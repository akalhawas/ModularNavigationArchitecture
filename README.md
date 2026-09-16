# Navigation

A small, dependency-free SwiftUI navigation layer built on `NavigationStack(path:)`. It gives every feature the same
toolkit for push/pop/present, and gives an app a way to let features navigate into *each other* without any feature
depending on another feature's *implementation* — views, use cases, networking.

Three things this layer is designed to make easy, and which this document covers in order:

1. **Internal navigation** — moving around inside a single feature.
2. **Cross-feature navigation** — feature A sending the user into feature B without feature A ever depending on
   feature B's module — only the app does.
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
| `Route` | Each feature's own module | Protocol your feature's screens conform to. Knows how to build its own view. Declared `public`, so both the app and any feature that needs to navigate into you can use it directly. |
| `AnyRoute` | `Navigation` | Type-erased `Route`, so a stack can hold routes from different `Route` types. |
| `NavigationRouter` | `Navigation` | Owns one navigation stack's state: push/pop/present. One per independent flow. |
| `NavigationHost` / `PresentedNavigationHost` | `Navigation` | SwiftUI wrappers that turn a `NavigationRouter` into an actual `NavigationStack`. They also inject the router into the environment for the whole stack. |
| `<Feature>CrossFeatureDelegate` | The *calling* feature's own module | A `weak`, class-bound protocol the feature declares for the one seam it needs to reach outside itself, named for its own concern (e.g. `onPrimaryAction`). Implemented by the app's coordinator. |
| `DeepLinkMapper` / `DeepLinkRouter` | Each `DeepLinkMapper` conformance lives inside the feature's own module; `DeepLinkRouter` itself lives in `Navigation` | Turns a `URL` into an `AnyRoute` directly. `DeepLinkRouter.shared` is a singleton; each feature registers its own mapper into it from inside its own `Module.register(...)`, the same call that wires its DI. |
| App coordinator | Your app target | Owns the app's top-level `NavigationRouter`s (and any tab/selection state), conforms to every feature's cross-feature delegate protocol, and turns an already-resolved deep-link `AnyRoute` into a navigation. Referred to below as `AppCoordinator` — the name is yours to choose. |

The flows in one line each:

- **Internal:** `View` → `router.navigate(to: SomeRoute.case)` → pushed onto `NavigationRouter.routes` → rendered by `NavigationHost`'s `NavigationStack`.
- **Cross-feature (in-app):** the feature calls a `weak` delegate protocol it defined itself and was handed at registration (e.g. `viewModel.crossFeatureDelegate?.onPrimaryAction(...)`) → the app's coordinator conforms to that protocol and, inside its conformance, builds the *other* feature's `Route` directly → `router.navigate(to:)`. The calling feature never imports the other feature's module or route type — only the app does.
- **Deep link (from the OS):** `URL` → `DeepLinkRouter.shared.resolve(url:)` (tries each registered `DeepLinkMapper` in order) → the mapper builds an `AnyRoute` from its own feature's `Route` type directly → `router.navigate(to:)`.

Both flows converge on the same final call, `router.navigate(to:)`, but there's no shared app-owned translation table in between — each feature's own `Route` type is public and used directly, either by that feature's own `DeepLinkMapper` or by the coordinator's delegate conformance. A feature's only involvement in cross-feature navigation is exposing a delegate protocol, in its own vocabulary, that the app conforms to — the feature never imports another feature's module.

## 1. Internal navigation (within a single feature)

### Define your feature's routes

```swift
import SwiftUI
import Navigation

public enum FeatureXRoute: Route {
    case main
    case detail(id: String)

    public func makeView(router: NavigationRouter) -> some View {
        switch self {
        case .main:
            FeatureXListView()
        case .detail(let id):
            FeatureXDetailView(id: id)
        }
    }
}
```

Every view in the flow gets the router via `@EnvironmentObject` — the hosting `NavigationHost` injects it once for
the whole stack, so `makeView` doesn't have to:

```swift
struct FeatureXListView: View {
    @EnvironmentObject var router: NavigationRouter

    var body: some View {
        Button("Open detail") {
            router.navigate(to: FeatureXRoute.detail(id: "42"))
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
router.pop()                                   // remove the top route
router.pop(count: 2)                            // remove the top N (clamped to stack size)
router.popTo { $0.matches(FeatureXRoute.main) }  // trim back to the last route matching a predicate
router.popToRoot()                               // clear the whole stack
```

### Presenting modally

```swift
router.presentSheet(FeatureXRoute.detail(id: "42"))              // uses the route's own `sheetDetents`
router.presentSheet(FeatureXRoute.detail(id: "42"), detents: [.medium]) // explicit override
router.presentFullScreen(FeatureXRoute.main)

router.dismissSheet()
router.dismissFullScreen()
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
NavigationHost(router: someRouter) {
    FeatureXListView()
}
```

Sheets and full-screen covers presented via `presentSheet`/`presentFullScreen` are hosted automatically inside a
fresh `PresentedNavigationHost` — you don't construct that type directly either.

## 2. Cross-feature navigation

**A feature never imports another feature's module.** Reaching another feature is always mediated by the app:
a feature declares a small, `weak`, class-bound delegate protocol for the one seam it needs, and the app's
coordinator is the sole conformer, since it's the only type that has both features in scope.

### Step 1 — The feature declares the seam it needs, as a protocol in its own vocabulary

```swift
// FeatureX/Presentation/CrossFeature/FeatureXCrossFeatureDelegate.swift
import Navigation

public protocol FeatureXCrossFeatureDelegate: AnyObject {
    func onPrimaryAction(router: NavigationRouter, id: Int, onReturn: @escaping () -> Void)
}
```

Name it for what `FeatureX` needs — never for the feature it happens to lead to.
`FeatureXModule.register(network:crossFeatureDelegate:)` takes this protocol as an optional parameter and threads it
down to wherever the button lives (through the feature's dependency graph to the view model), holding it `weak` at
every step — the delegate is normally the app's coordinator, and a strong reference back to it would leak. The button
calls `viewModel.crossFeatureDelegate?.onPrimaryAction(router, someId) { /* ... */ }` and does nothing else.

### Step 2 — The app conforms to the delegate and builds the target feature's route directly

```swift
// AppCoordinator.swift (app target)
extension AppCoordinator: FeatureXCrossFeatureDelegate {
    func onPrimaryAction(router: NavigationRouter, id: Int, onReturn: @escaping () -> Void) {
        router.navigate(to: FeatureYRoute.detail(id: id, onDismiss: onReturn), strategy: .push)
    }
}
```

No destination type, no registry lookup — the coordinator builds `FeatureYRoute` directly, because `FeatureYRoute`
is `public` and the app target can see it.

### Step 3 — The app wires the delegate in at registration

```swift
// App composition root
@MainActor
enum AppComposition {
    static func bootstrapFeatures(appCoordinator: AppCoordinator) {
        FeatureYModule.register(network: networkService)
        FeatureXModule.register(
            network: networkService,
            crossFeatureDelegate: appCoordinator
        )
    }
}
```

Re-export every feature's module from the app's entry point (`@_exported import FeatureX`,
`@_exported import FeatureY`, `@_exported import Navigation`) so the rest of the app target can reference
`FeatureXRoute` / `FeatureYRoute` directly without re-importing the feature module in every file. The coordinator is
still the only place that resolves one feature's cross-feature request into another feature's screen; neither feature
module ever imports the other, or imports the app.

## 3. Deep linking (from the OS)

Deep-link mappers live **inside each feature's own module**, next to that feature's `Route` type — not in the app
target. A feature owns its own deep links because it owns its own routes; there's no shared destination type to
translate through.

```swift
// FeatureY/Presentation/Routing/FeatureYDeepLinkMapper.swift
import Foundation
import Navigation

struct FeatureYDeepLinkMapper: DeepLinkMapper {
    // myapp://featurey/detail?id=1
    func map(url: URL) -> AnyRoute? {
        guard url.host == "featurey", url.path == "/detail",
              let id = url.queryItem("id").flatMap(Int.init) else { return nil }
        return AnyRoute(FeatureYRoute.detail(id: id))
    }
}
```

The feature registers its own mapper from inside its own `Module.register`, the same call that wires its DI:

```swift
// FeatureY/Dependencies/FeatureYModule.swift
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
// App entry point
.onOpenURL { url in
    guard let route = DeepLinkRouter.shared.resolve(url: url) else { return }
    appCoordinator.handleDeepLinkNavigation(to: route)
}
```

```swift
// AppCoordinator.swift
func handleDeepLinkNavigation(to route: AnyRoute) {
    // dismiss any presentation across every top-level router first
    allRouters.forEach { router in
        router.dismissSheet()
        router.dismissFullScreen()
    }

    // select the entry point that should own the link, then land the route as a fresh stack
    selectedTab = .someTab
    someRouter.navigate(to: route, strategy: .resetStack)
}
```

`DeepLinkRouter.resolve(url:)` hands back a ready-to-navigate `AnyRoute` directly — there's no second registry
lookup step.

Mappers are tried **in the order they were registered** — the order each feature's `Module.register` runs in the app
composition root. The first mapper to return non-`nil` wins. If two mappers could plausibly match the same URL,
register the more specific feature first.

## Checklist: wiring up a new feature

- [ ] Create the feature module, depending on `Navigation` (plus whatever it needs for networking) — no other feature module.
- [ ] Define `<FeatureName>Route: Route` with your screens; keep it `public` (the app, and any feature that navigates into you, need it).
- [ ] Build your views, reading `NavigationRouter` via `@EnvironmentObject`.
- [ ] `<FeatureName>Module.register(network:)` wires the feature's own DI (repositories/use cases/view models) **and** registers its own `DeepLinkMapper` with `DeepLinkRouter.shared` — both are the feature's own responsibility.
- [ ] *(Only if a deep link should reach in)* Add a `<FeatureName>DeepLinkMapper: DeepLinkMapper` inside the feature's own module (`Presentation/Routing/`), returning `AnyRoute(<FeatureName>Route.someCase(...))` directly from the mapped `URL`.
- [ ] *(For a feature that needs to navigate into another feature)* Declare a `<FeatureName>CrossFeatureDelegate: AnyObject` protocol in the feature's own module (`Presentation/CrossFeature/`), named for what it needs (e.g. `onPrimaryAction`); give `<FeatureName>Module.register` an extra `crossFeatureDelegate:` parameter, hold it `weak` all the way down to the view model, and have the app composition root pass the coordinator (which conforms to it) at registration.
- [ ] Host the feature's root under a `NavigationHost` somewhere (a tab, a nav-linked entry point), with its own `NavigationRouter`.

No feature module ever depends on another feature's module. Only the app target — via `@_exported import` at its
entry point — sees every feature's `Route` type at once, which is what lets the coordinator translate one feature's
cross-feature request into another feature's route.

## Gotchas & design notes

- **`DeepLinkRouter.shared` is a global singleton**, populated once per feature from inside that feature's own
  `Module.register(network:...)`, all called from the app composition root in the app's `init()`. Calling `resolve`
  before that has run will hit the miss path below. For unit tests, prefer creating a fresh
  `DeepLinkRouter(mappers: [])` instance rather than touching `.shared`, so tests don't leak registrations into
  each other.
- **`DeepLinkRouter.resolve(url:)` traps in Debug/test builds and returns `nil` in Release** when nothing matches
  (`assertionFailure` under the hood). This is intentional: Debug, CI, and test runs should catch a mistyped
  deep-link URL or a feature that forgot to register its mapper immediately and loudly; a shipped Release build
  degrades to a no-op instead of crashing for a user. One consequence: **don't** write a unit test that calls
  `resolve` with an unregistered URL under a normal test run — it will abort the whole test process, not
  fail one test. To verify the non-trapping Release behavior specifically, run the tests in release configuration.
- **`sheetDetents` is a real `Route` protocol requirement**, not just a protocol-extension default. That's
  deliberate — code that only knows `route.sheetDetents` through a generic `R: Route` constraint (which is exactly
  what `AnyRoute.init` and `presentSheet`/`presentFullScreen` do) needs it in the requirement list for a per-route
  override to actually take effect. If it were extension-only, a route's custom `sheetDetents` would silently be
  ignored and every route would present at `.large`. Don't move it back.
- **`PresentedNavigationHost` (used for sheets/full-screen) always creates its own fresh `NavigationRouter`.**
  There's no built-in way for a route pushed inside a presented flow to reach back into the presenting stack. If a
  presented flow needs to end by navigating the *parent* somewhere, model that explicitly (dismiss, then have the
  parent act on a result) rather than assuming the router can call upward.
- **`AnyRoute`'s `==` is value equality** based on the wrapped route's `Hashable` conformance — two pushes of the
  same case with the same associated values are considered the same route (this is what makes `popToIfExists` and
  `popTo(where:)` work). Its `id` (for `Identifiable`) is a fresh `UUID` per wrap, used only so SwiftUI's
  `.sheet(item:)`/`.fullScreenCover(item:)` can diff correctly — don't use `id` to compare routes.
- **`fullScreenCover` is unavailable on macOS.** `NavigationHost`/`PresentedNavigationHost` guard that one modifier
  behind `#if os(iOS)` so the package still compiles for macOS — this exists purely so the test suite can run on a
  host Mac without booting an iOS simulator. It has no effect on iOS behavior.
- **`FeatureModule`, `RouteRegistry`, and `NavigationDestination` still exist in `Navigation`.** They're an earlier
  design — destination enums translated through a central registry — that cross-feature and deep-link navigation
  have since moved away from in favor of using each feature's `Route` type directly. If you want a uniform
  registration hook across features, `FeatureModule` is still there to conform to; nothing forces that.

## Testing

`NavigationRouter` is a plain `ObservableObject` with no UIKit/SwiftUI-view dependency — drive it directly in unit
tests and assert on `routes`, the presented sheet/full-screen route, and how each `NavigationStrategy` mutates the
stack.

`DeepLinkRouter` is testable without the singleton: construct a fresh `DeepLinkRouter(mappers: [...])` (or register
into an empty one) so registrations don't leak between tests, then assert that a given `URL` resolves to the
expected `AnyRoute` — and that an unknown host/path resolves to `nil`. Because `resolve` traps on a miss in
Debug/test builds (see Gotchas), only exercise the non-trapping Release path in a release-configuration test run.

`AnyRoute` equality is worth a test per feature: two wraps of the same case with the same associated values compare
equal, different values don't, and `id` differs on every wrap.

An app-target coordinator that conforms to feature cross-feature delegates and handles deep links usually has no
unit-test target of its own; verify those paths manually against a running build:

```
xcrun simctl openurl booted "myapp://featurey/detail?id=1"
```
