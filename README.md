# Navigation

A small, dependency-free SwiftUI navigation layer built on `NavigationStack(path:)`. It gives every feature the same
toolkit for push/pop/present, and gives the app a way to let features navigate into *each other* without any feature
depending on another feature's *implementation* — views, use cases, networking.

Three things this package is designed to make easy, and which this document covers in order:

1. **Internal navigation** — moving around inside a single feature.
2. **Cross-feature navigation** — feature A sending the user into feature B without feature A ever depending on
   feature B's package — only the App does.
3. **Deep linking** — a URL landing the user on a specific screen, sharing the resolution half of #2's pipeline.

## Contents

- [Core concepts](#core-concepts)
- [1. Internal navigation](#1-internal-navigation-within-a-single-feature)
- [2. Cross-feature navigation](#2-cross-feature-navigation)
- [3. Deep linking](#3-deep-linking-from-the-os)
- [Checklist: wiring up a new feature](#checklist-wiring-up-a-new-feature)
- [Gotchas & design notes](#gotchas--design-notes)
- [Testing](#testing)

## Core concepts

| Type | Lives in | Purpose |
|---|---|---|
| `Route` | Each feature's own package | Protocol your feature's screens conform to. Knows how to build its own view. Declared `public`, so both the App and any feature that needs to navigate into you can use it directly. |
| `AnyRoute` | `Navigation` | Type-erased `Route`, so a stack can hold routes from different `Route` types. |
| `NavigationCoordinator` | `Navigation` | Owns one navigation stack's state: push/pop/present. One per independent flow. |
| `NavigationHost` / `PresentedNavigationHost` | `Navigation` | SwiftUI wrappers that turn a `NavigationCoordinator` into an actual `NavigationStack`. |
| `<Feature>CrossFeatureDelegate` | The *calling* feature's own package | A `weak`, class-bound protocol the feature declares for the one seam it needs to reach outside itself, named for its own concern (e.g. `onPrimaryAction`). Implemented by the App's `AppCoordinator`. |
| `DeepLinkMapper` / `DeepLinkRouter` | Each `DeepLinkMapper` conformance lives inside the feature's own package; `DeepLinkRouter` itself lives in `Navigation` | Turns a `URL` into an `AnyRoute` directly. `DeepLinkRouter.shared` is a singleton; each feature registers its own mapper into it from inside its own `Module.register(...)`, the same call that wires its DI. |
| `AppCoordinator` | App target, `Coordinator/AppCoordinator.swift` | Owns the app's top-level `NavigationCoordinator`s and selected tab, conforms to every feature's cross-feature delegate protocol, and turns an already-resolved deep-link `AnyRoute` into a navigation. |

The flows in one line each:

- **Internal:** `View` → `coordinator.navigate(to: SomeRoute.case)` → pushed onto `NavigationCoordinator.routes` → rendered by `NavigationHost`'s `NavigationStack`.
- **Cross-feature (in-app):** the feature calls a `weak` delegate protocol it defined itself and was handed at registration (e.g. `viewModel.crossFeatureDelegate?.onPrimaryAction(...)`) → the App's `AppCoordinator` conforms to that protocol and, inside its conformance, builds the *other* feature's `Route` directly → `coordinator.navigate(to:)`. The calling feature never imports the other feature's package or route type — only the App does.
- **Deep link (from the OS):** `URL` → `DeepLinkRouter.shared.resolve(url:)` (tries each registered `DeepLinkMapper` in order) → the mapper builds an `AnyRoute` from its own feature's `Route` type directly → `coordinator.navigate(to:)`.

Both flows converge on the same final call, `coordinator.navigate(to:)`, but there's no shared App-owned translation table in between anymore — each feature's own `Route` type is public and used directly, either by that feature's own `DeepLinkMapper` or by `AppCoordinator`'s delegate conformance. A feature's only involvement in cross-feature navigation is exposing a delegate protocol, in its own vocabulary, that the App conforms to — the feature never imports another feature's package.

## 1. Internal navigation (within a single feature)

### Define your feature's routes

```swift
import SwiftUI
import Navigation

public enum FeatureXRoute: Route {
    case main
    case detail(id: String)

    public func makeView(coordinator: NavigationCoordinator) -> some View {
        switch self {
        case .main:
            FeatureXListView().environmentObject(coordinator)
        case .detail(let id):
            FeatureXDetailView(id: id).environmentObject(coordinator)
        }
    }
}
```

Every view in the flow gets the coordinator via `@EnvironmentObject` (set up once by whatever hosts the stack — see
below):

```swift
struct FeatureXListView: View {
    @EnvironmentObject var coordinator: NavigationCoordinator

    var body: some View {
        Button("Open detail") {
            coordinator.navigate(to: FeatureXRoute.detail(id: "42"))
        }
    }
}
```

### Choosing a navigation strategy

`navigate(to:strategy:)` takes a `NavigationStrategy`, default `.push`:

| Strategy | Behavior |
|---|---|
| `.push` | Appends the route to the stack (normal drill-in). |
| `.resetStack` | Replaces the *entire* stack with just this route. Use for "start fresh here" flows — deep links landing mid-stack, tab resets. |
| `.popToIfExists` | If the route is already somewhere in the stack, pops back to it; otherwise pushes it. Use for "go to my cart" style shortcuts that shouldn't stack duplicates. |

### Popping

```swift
coordinator.pop()                                   // remove the top route
coordinator.pop(count: 2)                            // remove the top N (clamped to stack size)
coordinator.popTo { $0.matches(FeatureXRoute.main) }  // trim back to the last route matching a predicate
coordinator.popToRoot()                               // clear the whole stack
```

### Presenting modally

```swift
coordinator.presentSheet(FeatureXRoute.detail(id: "42"))              // uses the route's own `sheetDetents`
coordinator.presentSheet(FeatureXRoute.detail(id: "42"), detents: [.medium]) // explicit override
coordinator.presentFullScreen(FeatureXRoute.main)

coordinator.dismissSheet()
coordinator.dismissFullScreen()
```

A route can declare its own default sheet detents (used whenever `presentSheet` is called *without* an explicit
`detents:` argument):

```swift
public enum FeatureXRoute: Route {
    case detail(id: String)

    public var sheetDetents: Set<PresentationDetent> { [.medium] }
    // ...
}
```

### Hosting a stack

You only need this once per *independent* navigation flow — an app root, a tab root, or a standalone entry point.
Individual feature screens never construct this themselves.

```swift
NavigationHost(coordinator: someCoordinator) {
    FeatureXListView().environmentObject(someCoordinator)
}
```

Sheets and full-screen covers presented via `presentSheet`/`presentFullScreen` are hosted automatically inside a
fresh `PresentedNavigationHost` — you don't construct that type directly either.

## 2. Cross-feature navigation

**A feature never imports another feature's package.** Reaching another feature is always mediated by the App:
a feature declares a small, `weak`, class-bound delegate protocol for the one seam it needs, and `AppCoordinator`
(in the App target) is the sole conformer, since it's the only type that has both features in scope.

### Step 1 — The feature declares the seam it needs, as a protocol in its own vocabulary

```swift
// Packages/Features/FeatureX/Sources/FeatureX/Presentation/CrossFeature/FeatureXCrossFeatureDelegate.swift
import Navigation

public protocol FeatureXCrossFeatureDelegate: AnyObject {
    func onSecondaryAction(coordinator: NavigationCoordinator, id: Int, onReturn: @escaping () -> Void)
}
```

Name it for what `FeatureX` needs — never for the feature it happens to lead to. `FeatureXModule.register(network:crossFeatureDelegate:)` takes this protocol as an optional parameter and threads it down to wherever the button lives (through `FeatureXDependencies` → `FeatureXViewModels` → the view model), holding it `weak` at every step — the delegate is normally the App's coordinator, and a strong reference back to it would leak. The button calls `viewModel.crossFeatureDelegate?.onSecondaryAction(coordinator, someId) { /* ... */ }` and does nothing else.

### Step 2 — The App conforms to the delegate and builds the target feature's route directly

```swift
// Coordinator/AppCoordinator.swift
extension AppCoordinator: FeatureXCrossFeatureDelegate {
    func onSecondaryAction(coordinator: NavigationCoordinator, id: Int, onReturn: @escaping () -> Void) {
        coordinator.navigate(to: FeatureYRoute.details(id: id, onDetailAction: onReturn), strategy: .push)
    }
}
```

No destination type, no registry lookup — `AppCoordinator` builds `FeatureYRoute` directly, because `FeatureYRoute` is `public` and the App target can see it.

### Step 3 — The App wires the delegate in at registration

```swift
// App/AppComposition.swift
@MainActor
enum AppComposition {
    static func bootstrapFeatures(appCoordinator: AppCoordinator) {
        FeatureYModule.register(network: AppDependencies.shared.networkService)
        FeatureXModule.register(
            network: AppDependencies.shared.networkService,
            crossFeatureDelegate: appCoordinator
        )
    }
}
```

`App/ModularNavigationExampleApp.swift` re-exports every feature's package (`@_exported import FeatureX`,
`@_exported import FeatureY`, `@_exported import Navigation`), so the rest of the App target — `AppComposition`,
`AppCoordinator`, `TabBarView`, `ServicesView`, `HomeView` — can reference `FeatureXRoute`/`FeatureYRoute` directly
without re-importing the feature package in every file. `AppCoordinator` is still the only place that resolves one
feature's cross-feature request into another feature's screen; neither feature package ever imports the other, or
imports the App.

## 3. Deep linking (from the OS)

Deep-link mappers live **inside each feature's own package**, next to that feature's `Route` type — not in the App
target. A feature owns its own deep links because it owns its own routes; there's no shared destination type to
translate through anymore.

```swift
// Packages/Features/FeatureY/Sources/FeatureY/Presentation/Routing/FeatureYDeepLinkMapper.swift
import Foundation
import Navigation

struct FeatureYDeepLinkMapper: DeepLinkMapper {
    // xcrun simctl openurl booted "com.ali.modularnavigationexample://featurey/details?id=1"
    func map(url: URL) -> AnyRoute? {
        guard url.host == "featurey", url.path == "/details",
              let id = url.queryItem("id").flatMap(Int.init) else { return nil }
        return AnyRoute(FeatureYRoute.details(id: id))
    }
}
```

The feature registers its own mapper from inside its own `Module.register`, the same call that wires its DI:

```swift
// Packages/Features/FeatureY/Sources/FeatureY/Dependencies/FeatureYModule.swift
public static func register(network: NetworkService) {
    let dependencies = FeatureYDependencies(network: network)
    viewModels = { dependencies.viewModels }
    registerRouting()
}

private static func registerRouting() {
    DeepLinkRouter.shared.register(FeatureYDeepLinkMapper())
}
```

```swift
// App/ModularNavigationExampleApp.swift
.onOpenURL { url in
    guard let route = DeepLinkRouter.shared.resolve(url: url) else { return }
    appCoordinator.handleDeepLinkNavigation(to: route)
}
```

```swift
// Coordinator/AppCoordinator.swift
func handleDeepLinkNavigation(to route: AnyRoute) {
    allCoordinators.forEach { coordinator in
        coordinator.dismissSheet()
        coordinator.dismissFullScreen()
    }

    selectedTab = .services
    servicesCoordinator.navigate(to: route, strategy: .resetStack)
}
```

`DeepLinkRouter.resolve(url:)` now hands back a ready-to-navigate `AnyRoute` directly — there's no second
registry lookup step the way there used to be.

Mappers are tried **in the order they were registered** — the order each feature's `Module.register` runs in `AppComposition.bootstrapFeatures()`. The first mapper to return non-`nil` wins. If two mappers could plausibly match the same URL, register the more specific feature first.

## Checklist: wiring up a new feature

- [ ] Create the SPM package under `Packages/Features/<FeatureName>`, depending on `Navigation` + `NetworkService` (via `SharedLibraries`) — nothing else.
- [ ] Define `<FeatureName>Route: Route` with your screens; keep it `public` (the App, and any feature that navigates into you, need it).
- [ ] Build your views, reading `NavigationCoordinator` via `@EnvironmentObject`.
- [ ] `<FeatureName>Module.register(network:)` wires the feature's own DI (repositories/use cases/view models) **and** registers its own `DeepLinkMapper` with `DeepLinkRouter.shared` — both are the feature's own responsibility now.
- [ ] *(Only if a deep link should reach in)* Add a `<FeatureName>DeepLinkMapper: DeepLinkMapper` inside the feature's own package (`Presentation/Routing/`), returning `AnyRoute(<FeatureName>Route.someCase(...))` directly from the mapped `URL`.
- [ ] *(For a feature that needs to navigate into another feature)* Declare a `<FeatureName>CrossFeatureDelegate: AnyObject` protocol in the feature's own package (`Presentation/CrossFeature/`), named for what it needs (e.g. `onSecondaryAction`); give `<FeatureName>Module.register` an extra `crossFeatureDelegate:` parameter, hold it `weak` all the way down to the view model, and have `AppComposition` pass `appCoordinator` (which conforms to it) at registration.
- [ ] Host the feature's root under a `NavigationHost` somewhere (a tab, a nav-linked entry point), with its own `NavigationCoordinator`.

No feature package ever depends on another feature's package. Only the App target — via `@_exported import` in
`App/ModularNavigationExampleApp.swift` — sees every feature's `Route` type at once, which is what lets
`AppCoordinator` translate one feature's cross-feature request into another feature's route.

## Gotchas & design notes

- **`DeepLinkRouter.shared` is a global singleton**, populated once per feature from inside that feature's own
  `Module.register(network:...)`, all called from `AppComposition.bootstrapFeatures()` in the app's `init()`.
  Calling `resolve` before that has run will hit the miss path below. For unit tests, prefer creating a fresh
  `DeepLinkRouter(mappers: [])` instance rather than touching `.shared`, so tests don't leak registrations into
  each other.
- **`DeepLinkRouter.resolve(url:)` traps in Debug/test builds and returns `nil` in Release** when nothing matches
  (`assertionFailure` under the hood). This is intentional: Debug, CI, and test runs should catch a mistyped
  deep-link URL or a feature that forgot to register its mapper immediately and loudly; a shipped Release build
  degrades to a no-op instead of crashing for a user. One consequence: **don't** write a unit test that calls
  `resolve` with an unregistered URL under a normal `swift test` run — it will abort the whole test process, not
  fail one test. If you need to verify the non-trapping Release behavior specifically, run `swift test -c release`.
- **`sheetDetents` is a real `Route` protocol requirement**, not just a protocol-extension default. That's
  deliberate — code that only knows `route.sheetDetents` through a generic `R: Route` constraint (which is exactly
  what `AnyRoute.init` and `presentSheet`/`presentFullScreen` do) needs it in the requirement list for a per-route
  override to actually take effect. If it were extension-only, a route's custom `sheetDetents` would silently be
  ignored and every route would present at `.large`. Don't move it back.
- **`PresentedNavigationHost` (used for sheets/full-screen) always creates its own fresh `NavigationCoordinator`.**
  There's no built-in way for a route pushed inside a presented flow to reach back into the presenting stack. If a
  presented flow needs to end by navigating the *parent* somewhere, model that explicitly (dismiss, then have the
  parent act on a result) rather than assuming the coordinator can call upward.
- **`AnyRoute`'s `==` is value equality** based on the wrapped route's `Hashable` conformance — two pushes of the
  same case with the same associated values are considered the same route (this is what makes `popToIfExists` and
  `popTo(where:)` work). Its `id` (for `Identifiable`) is a fresh `UUID` per wrap, used only so SwiftUI's
  `.sheet(item:)`/`.fullScreenCover(item:)` can diff correctly — don't use `id` to compare routes.
- **`fullScreenCover` is unavailable on macOS.** `NavigationHost`/`PresentedNavigationHost` guard that one modifier
  behind `#if os(iOS)` so the package still compiles for macOS — this exists purely so `swift test` can run on the
  host Mac without booting an iOS simulator. It has no effect on iOS behavior.
- **`FeatureModule`, `RouteRegistry`, and `NavigationDestination` still exist in `Navigation` but aren't used by
  this app.** They're an earlier design — destination enums translated through a central registry — that
  cross-feature and deep-link navigation have since moved away from in favor of using each feature's `Route` type
  directly. `UsersModule`/`ColorsModule` expose a plain `register(network:...)` static method that wires the
  feature's own DI *and* registers its own `DeepLinkMapper` with `DeepLinkRouter.shared` in that same call. If you
  want a uniform registration hook across features, `FeatureModule` is still there to conform to; nothing currently
  depends on that happening.

## Testing

`Navigation` lives in the separate `SharedLibraries` package (pulled in via SPM) — there's no `Navigation` package
inside this repo. To run its test suite, `cd` into wherever `SharedLibraries` is checked out and:

```
swift test --filter NavigationTests
```

Runs on macOS directly — no simulator needed, finishes in well under a second. Coverage lives in
`Tests/NavigationTests`: `NavigationCoordinatorTests`, `RouteRegistryTests`, `AnyRouteTests`, `DeepLinkRouterTests`,
and `URLQueryItemTests`.

For this repo's own feature-level coverage — e.g. `ColorsViewModelTests` or `UsersViewModelTests`, which test the
feature's views and use cases — run the package's own test target, since the app scheme itself isn't
currently wired for the test action:

```
xcodebuild test -scheme FeatureY -destination 'platform=iOS Simulator,name=<simulator name>'
```

`App/AppComposition.swift` and `Coordinator/AppCoordinator.swift` have no automated test coverage — there is
no Xcode unit test target for the `App` target itself. Verify deep links manually against a booted simulator:

```
xcrun simctl openurl booted "com.ali.modularnavigationexample://users/details?id=1"
xcrun simctl openurl booted "com.ali.modularnavigationexample://colors/details?id=1"
```
