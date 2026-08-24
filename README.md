# Navigation

A small, dependency-free SwiftUI navigation layer built on `NavigationStack(path:)`. It gives every feature the same
toolkit for push/pop/present, and gives the app a way to let features navigate into *each other* without any feature
depending on another feature's *implementation* — views, use cases, networking.

Three things this package is designed to make easy, and which this document covers in order:

1. **Internal navigation** — moving around inside a single feature.
2. **Cross-feature navigation** — feature A sending the user into feature B by depending only on B's small `API`
   target, never B's main target.
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
| `Route` | `Navigation` | Protocol your feature's screens conform to. Knows how to build its own view. |
| `AnyRoute` | `Navigation` | Type-erased `Route`, so a stack can hold routes from different `Route` types. |
| `NavigationCoordinator` | `Navigation` | Owns one navigation stack's state: push/pop/present. One per independent flow. |
| `NavigationHost` / `PresentedNavigationHost` | `Navigation` | SwiftUI wrappers that turn a `NavigationCoordinator` into an actual `NavigationStack`. |
| `NavigationDestination` | `Navigation` (protocol) | A small allowlist of entry points into one feature, reachable from outside it. Declared `public` inside `App/Destinations/`, not inside the feature's own package — the App owns every feature's destination, so no feature ever depends on another feature's package to reach it. |
| `RouteRegistry` | `Navigation` | Resolves a `NavigationDestination` into a real `AnyRoute`, without the caller knowing the feature's route type. |
| `DeepLinkMapper` / `DeepLinkRouter` | `Navigation` | Turns a `URL` into a `NavigationDestination`. `DeepLinkRouter.shared` is a singleton; each feature registers its own mapper into it at startup, the same way it registers with `RouteRegistry.shared`. |

The flows in one line each:

- **Internal:** `View` → `coordinator.navigate(to: SomeRoute.case)` → pushed onto `NavigationCoordinator.routes` → rendered by `NavigationHost`'s `NavigationStack`.
- **Cross-feature (in-app):** the feature calls a closure it defined itself and was handed at registration (e.g. `viewModel.crossFeatureActions.onSecondaryAction(...)`) → the App's implementation of that closure resolves the *other* feature's `Destination` via `RouteRegistry.shared.resolve(_:)` → `AnyRoute` → `coordinator.navigate(to:)`. The calling feature never sees the destination type or the registry — only the App does.
- **Deep link (from the OS):** `URL` → `DeepLinkRouter.shared.resolve(url:)` (tries each registered `DeepLinkMapper` in order) → `NavigationDestination` → `RouteRegistry.shared.resolve(_:)` → `AnyRoute` → `coordinator.navigate(to:)`.

Both flows share the same back half (`RouteRegistry` → `AnyRoute` → `coordinator.navigate`), but only the App ever performs it. A feature's only involvement in cross-feature navigation is exposing a closure, in its own vocabulary, that the App fills in — the feature never imports `NavigationDestination`, `RouteRegistry`, or another feature's package.

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

**A feature never imports another feature's package, or `NavigationDestination`/`RouteRegistry`/`DeepLinkRouter` at all.** Every destination, every deep-link mapper, and every `RouteRegistry`/`DeepLinkRouter` registration lives in the App target — `App/Destinations/`, `App/Routing/`, and `App/AppComposition.swift`. A feature's only role in reaching another feature is exposing a closure, named for its own concern, that the App fills in with the real behavior.

### Step 1 — The feature declares the seam it needs, in its own vocabulary

```swift
// Packages/Features/FeatureX/Sources/FeatureX/Dependencies/FeatureXCrossFeatureActions.swift
import Navigation

public struct FeatureXCrossFeatureActions {
    public let onSecondaryAction: (NavigationCoordinator, Int, @escaping () -> Void) -> Void
    public init(onSecondaryAction: @escaping (NavigationCoordinator, Int, @escaping () -> Void) -> Void) {
        self.onSecondaryAction = onSecondaryAction
    }
}
```

Name it for what `FeatureX` needs — never for the feature it happens to lead to. `FeatureXModule.register(network:crossFeatureActions:)` takes this struct as a parameter and threads it down to wherever the button lives; the button calls `viewModel.crossFeatureActions.onSecondaryAction(coordinator, someId) { /* ... */ }` and does nothing else.

### Step 2 — The App declares the target feature's destination

```swift
// App/Destinations/FeatureYDestination.swift
import Navigation

public enum FeatureYDestination: NavigationDestination {
    case details(id: Int)
}
```

### Step 3 — The App registers `FeatureY`'s destination and builds `FeatureX`'s closure

```swift
// App/AppComposition.swift
static func bootstrapFeatures(mainCoordinator: MainCoordinator) {
    FeatureYModule.register(network: AppDependencies.shared.networkService)
    registerFeatureYRouting() // RouteRegistry.shared.register(FeatureYDestination.self) { ... }

    FeatureXModule.register(
        network: AppDependencies.shared.networkService,
        crossFeatureActions: FeatureXCrossFeatureActions(
            onSecondaryAction: mainCoordinator.handleFeatureXSecondaryAction
        )
    )
}
```

```swift
// App/MainCoordinator.swift
extension MainCoordinator {
    func handleFeatureXSecondaryAction(coordinator: NavigationCoordinator, id: Int, onReturn: @escaping () -> Void) {
        guard let route = RouteRegistry.shared.resolve(FeatureYDestination.details(id: id)) else { return }
        coordinator.navigate(to: route)
    }
}
```

`AppComposition` is the only file that imports both `FeatureX` and `FeatureY` (and every `Destination` type) together — because it's the only place that needs to. `MainCoordinator` holds the actual navigation behavior, extending the same role it already plays for deep links (`handleDeepLinkNavigation`). Neither feature package ever depends on the other, and neither imports `NavigationDestination`, `RouteRegistry`, or `DeepLinkRouter`.

## 3. Deep linking (from the OS)

Deep-link mappers live in `App/Routing/`, next to the `Destination` types in `App/Destinations/` that they produce — not inside the feature packages. A feature package has no involvement in deep linking at all.

```swift
// App/Routing/FeatureYDeepLinkMapper.swift
import Foundation
import Navigation

struct FeatureYDeepLinkMapper: DeepLinkMapper {
    // xcrun simctl openurl booted "com.ali.modularnavigationexample://featurey/details?id=1"
    func map(url: URL) -> (any NavigationDestination)? {
        guard url.host == "featurey", url.path == "/details",
              let id = url.queryItem("id") else { return nil }
        return FeatureYDestination.details(id: Int(id) ?? 0)
    }
}
```

```swift
// App/AppComposition.swift
private static func registerFeatureYRouting() {
    RouteRegistry.shared.register(FeatureYDestination.self) { destination in
        switch destination {
        case .details(let id): return AnyRoute(FeatureYRoute.detail(id: id))
        }
    }
    DeepLinkRouter.shared.register(FeatureYDeepLinkMapper())
}
```

```swift
// App/ModularNavigationExampleApp.swift
.onOpenURL { url in
    guard let destination = DeepLinkRouter.shared.resolve(url: url) else { return }
    mainCoordinator.handleDeepLinkNavigation(to: destination)
}
```

```swift
// App/MainCoordinator.swift
func handleDeepLinkNavigation(to destination: any NavigationDestination) {
    allCoordinators.forEach { coordinator in
        coordinator.dismissSheet()
        coordinator.dismissFullScreen()
    }

    switch destination {
    default:
        guard let route = RouteRegistry.shared.resolve(destination) else { return }
        selectedTab = .services
        servicesCoordinator.navigate(to: route, strategy: .push)
    }
}
```

Mappers are tried **in the order they were registered** — the order each feature's `registerXRouting()` runs in `AppComposition.bootstrapFeatures()`. The first mapper to return non-`nil` wins. If two mappers could plausibly match the same URL, register the more specific one first.

## Checklist: wiring up a new feature

- [ ] Create the SPM package under `Packages/Features/<FeatureName>`, depending on `Navigation` + `NetworkService` (via `SharedLibraries`) — nothing else.
- [ ] Define `<FeatureName>Route: Route` with your screens; keep it `public` (the App needs it).
- [ ] Build your views, reading `NavigationCoordinator` via `@EnvironmentObject`.
- [ ] `<FeatureName>Module.register(network:)` should only wire the feature's own DI (repositories/use cases/view models) — never touch `RouteRegistry`/`DeepLinkRouter`.
- [ ] *(Only if other features or deep links must reach in)* Add `public <FeatureName>Destination: NavigationDestination` to `App/Destinations/` — not to the feature's own package.
- [ ] *(Only if the above)* Add a `<FeatureName>DeepLinkMapper: DeepLinkMapper` to `App/Routing/`, and register both it and the destination from `App/AppComposition.swift`.
- [ ] *(For a feature that needs to navigate into another feature)* Give `<FeatureName>Module.register` an extra parameter for the closure it needs (named for the feature's own concern, e.g. `crossFeatureActions:`), thread it down to wherever the trigger lives, and have `AppComposition` supply the real implementation using `MainCoordinator`.
- [ ] Host the feature's root under a `NavigationHost` somewhere (a tab, a nav-linked entry point), with its own `NavigationCoordinator`.

No feature package ever depends on another feature's package, or on `NavigationDestination`/`RouteRegistry`/`DeepLinkRouter` — those are exclusively `App/`'s concern.

## Gotchas & design notes

- **`RouteRegistry.shared` and `DeepLinkRouter.shared` are global singletons**, populated by each feature's own
  `register()`, called once from `AppComposition.bootstrapFeatures()` in the app's `init()`. Calling either
  `resolve` before that has run will hit the miss path below. For unit tests, prefer creating fresh
  `RouteRegistry()`/`DeepLinkRouter(mappers: [])` instances rather than touching `.shared`, so tests don't leak
  registrations into each other.
- **Both `RouteRegistry.resolve(_:)` and `DeepLinkRouter.resolve(url:)` trap in Debug/test builds and return `nil`
  in Release** when nothing matches (`assertionFailure` under the hood, in both). This is intentional: Debug, CI,
  and test runs should catch a forgotten registration or a mistyped deep-link URL immediately and loudly; a shipped
  Release build degrades to a no-op instead of crashing for a user. One consequence: **don't** write a unit test
  that calls either `resolve` with an unregistered value under a normal `swift test` run — it will abort the whole
  test process, not fail one test. If you need to verify the non-trapping Release behavior specifically, run
  `swift test -c release`.
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
- **`FeatureModule` exists in `Navigation` but isn't currently adopted.** Features expose a plain `register(network:)`
  static method (`UsersModule`, `ColorsModule`) for their own DI only — it no longer touches `RouteRegistry`/
  `DeepLinkRouter` at all. `AppComposition.bootstrapFeatures()` calls each feature's `register`, then separately
  registers that feature's destination/mapper itself. If you want a uniform registration hook across features,
  conform to `FeatureModule`; nothing currently depends on that happening.

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

`App/Destinations/`, `App/Routing/`, and `App/AppComposition.swift` have no automated test coverage — there is
no Xcode unit test target for the `App` target itself. Verify deep links manually against a booted simulator:

```
xcrun simctl openurl booted "com.ali.modularnavigationexample://users/details?id=1"
xcrun simctl openurl booted "com.ali.modularnavigationexample://colors/details?id=1"
```
