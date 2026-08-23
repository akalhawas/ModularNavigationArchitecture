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
| `NavigationDestination` | `Navigation` (protocol) | A small, feature-owned allowlist of entry points reachable from outside that feature. Declared `public` inside a lightweight `<FeatureName>API` target — a separate SPM product from the feature's main target — so other features can depend on just the destination type, not the feature's views, use cases, or networking. |
| `RouteRegistry` | `Navigation` | Resolves a `NavigationDestination` into a real `AnyRoute`, without the caller knowing the feature's route type. |
| `DeepLinkMapper` / `DeepLinkRouter` | `Navigation` | Turns a `URL` into a `NavigationDestination`. `DeepLinkRouter.shared` is a singleton; each feature registers its own mapper into it at startup, the same way it registers with `RouteRegistry.shared`. |

The flows in one line each:

- **Internal:** `View` → `coordinator.navigate(to: SomeRoute.case)` → pushed onto `NavigationCoordinator.routes` → rendered by `NavigationHost`'s `NavigationStack`.
- **Cross-feature (in-app):** caller imports the callee's `<FeatureName>API` product → constructs `<FeatureName>Destination` directly → `RouteRegistry.shared.resolve(_:)` → `AnyRoute` → `coordinator.navigate(to:)`.
- **Deep link (from the OS):** `URL` → `DeepLinkRouter.shared.resolve(url:)` (tries each registered `DeepLinkMapper` in order) → `NavigationDestination` → `RouteRegistry.shared.resolve(_:)` → `AnyRoute` → `coordinator.navigate(to:)`.

Both flows share the same back half (`RouteRegistry` → `AnyRoute` → `coordinator.navigate`) and only differ in how
the `NavigationDestination` value comes into existence: constructed directly and type-checked at compile time for an
in-app caller that depends on `<FeatureName>API`, or parsed out of a `URL` string by a `DeepLinkMapper` for anything
that can only hand you a URL (Safari, Messages, a push notification, `xcrun simctl openurl`). A feature only needs
the `DeepLinkMapper` half if it should also be reachable by a real OS deep link — a destination that's only ever
navigated to in-app from another feature doesn't need one.

Depending on `<FeatureName>API` reintroduces a compile-time dependency between features, so it only works
one-directionally: if `FeatureX` depends on `FeatureYAPI`, `FeatureY` (or `FeatureYAPI`) cannot depend on `FeatureX`
or `FeatureXAPI` — SPM will not resolve a circular package graph. If two features need to reach *each other* in-app,
pick one direction for the `API`-target dependency and have the other direction go through the URL/`DeepLinkRouter`
path instead.

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

**Never import one feature's *main* target from another to navigate into it.** That would pull in its views, use
cases, and networking just to build a route. Instead, a feature that wants to be reachable from other features
exposes a second, minimal SPM product — `<FeatureName>API` — containing nothing but its `NavigationDestination`.
Callers depend on that product only. In this example, `FeatureX` depends on `FeatureY`'s `FeatureYAPI` product (and
nothing else from `FeatureY`); `FeatureY` has no dependency on `FeatureX` at all, which is what keeps the package
graph acyclic.

### Step 1 — Declare the destination(s) your feature exposes, in a separate `<FeatureName>API` target

```swift
// Packages/Features/FeatureY/Sources/FeatureYAPI/FeatureYDestination.swift
import Navigation

/// Defines public entry points into the FeatureY feature.
///
/// Used for cross-feature navigation and deep linking. This is the only
/// thing other features/the app need to depend on to navigate into FeatureY —
/// it does not pull in FeatureY's SwiftUI views, networking, or use cases.
public enum FeatureYDestination: NavigationDestination {
    case details(id: Int)
}
```

```swift
// Packages/Features/FeatureY/Package.swift
products: [
    .library(name: "FeatureYAPI", targets: ["FeatureYAPI"]),
    .library(name: "FeatureY", targets: ["FeatureY"]),
],
targets: [
    .target(name: "FeatureYAPI", dependencies: [.product(name: "Navigation", package: "SharedLibraries")]),
    .target(name: "FeatureY", dependencies: ["FeatureYAPI", /* ... */]),
    // ...
]
```

Keep `FeatureYDestination` to *only* the cases meant to be reachable from outside — it does not need to mirror your
feature's `Route` type. `FeatureYRoute` also has a `.list` case with no `FeatureYDestination` counterpart, on
purpose: nobody should be able to jump straight to "the list" from outside the feature. Adding a case here is a
deliberate, visible step — that's what keeps the external surface intentional instead of accidental. The `FeatureY`
main target re-exposes it as `"FeatureYAPI"` in its own dependency list purely so `FeatureY`'s own files (the
mapper, the module registration below) can `import FeatureYAPI` alongside `Navigation`.

### Step 2 — Write a mapper, and register both it and the destination from your own module

```swift
// Packages/Features/FeatureY/Sources/FeatureY/Presentation/Routing/FeatureYDeepLinkMapper.swift
import Navigation
import FeatureYAPI

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
// Packages/Features/FeatureY/Sources/FeatureY/Dependencies/FeatureYModule.swift
public enum FeatureYModule {
    public static func register(network: NetworkService) {
        // ... build dependencies ...
        registerPublicEntryPoint()
    }

    private static func registerPublicEntryPoint() {
        RouteRegistry.shared.register(FeatureYDestination.self) { destination in
            switch destination {
            case .details(let id):
                return AnyRoute(FeatureYRoute.detail(id: id))
            }
        }
        DeepLinkRouter.shared.register(FeatureYDeepLinkMapper())
    }
}
```

`FeatureYModule.register(network:)` is called once at app launch from `AppComposition.bootstrapFeatures()` — see
`App/AppComposition.swift`. There's no central place that assembles a list of every feature's mapper; each feature
registers its own into the shared `DeepLinkRouter.shared`/`RouteRegistry.shared` singletons.

### Step 3 — Navigate in from another feature, using `<FeatureName>API` + `Navigation`

```swift
// Packages/Features/FeatureX/Sources/FeatureX/Presentation/View/FeatureXView.swift
import FeatureYAPI

Button {
    let destination = FeatureYDestination.details(id: 1)
    guard let route = RouteRegistry.shared.resolve(destination) else { return }
    coordinator.navigate(to: route)
} label: { /* ... */ }
```

`FeatureXView` imports `FeatureYAPI` — nothing else from `FeatureY` — and constructs `FeatureYDestination` directly,
so a typo in the case name or its arguments is a compile error, not a silent no-op at runtime. If `FeatureY`'s
*internal* route shape changes (its `FeatureYRoute` cases, its view models), nothing here needs to change as long as
`FeatureYModule`'s `RouteRegistry.shared.register(FeatureYDestination.self) { ... }` mapping still produces a valid
route — `FeatureYAPI` is the only contract `FeatureXView` depends on.

This requires `FeatureX`'s `Package.swift` to add a local dependency on `FeatureY` and depend on its `FeatureYAPI`
product (not `FeatureY` itself):

```swift
// Packages/Features/FeatureX/Package.swift
dependencies: [
    .package(url: "https://github.com/akalhawas/SharedLibraries.git", from: "0.1.3"),
    .package(path: "../FeatureY"),
],
targets: [
    .target(name: "FeatureX", dependencies: ["FeatureXAPI", /* ... */, .product(name: "FeatureYAPI", package: "FeatureY")]),
    // ...
]
```

If a caller can only hand you a `URL` (see §3 below) rather than construct the destination directly in Swift, the
same `RouteRegistry.shared.resolve(_:)` step still applies — only the first step (getting to a `NavigationDestination`)
differs, going through `DeepLinkRouter.shared.resolve(url:)` and a `DeepLinkMapper` instead of a direct initializer.

## 3. Deep linking (from the OS)

This reuses the *second half* of §2's pipeline (`RouteRegistry.shared.resolve(_:) → AnyRoute → coordinator.navigate`)
but starts from a real `URL` instead of a direct `<FeatureName>API` construction — the OS hands the URL to you via
`.onOpenURL`, and a registered `DeepLinkMapper` turns it into the same `NavigationDestination` an in-app caller
would have built directly.

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
    /// remove all presentation
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

Deciding *where* to land (which tab, which coordinator) has to happen at this top level — a deep link can arrive
while the user is anywhere in the app. `.resetStack`/`.push` here is a per-app call; this example always pushes onto
the `services` tab's stack. Before that, it dismisses any sheet/full-screen presentation on *every* coordinator
(`allCoordinators`, not just `servicesCoordinator`) — a deep link can land while the user has something presented on
a different tab entirely.

Mappers are tried **in the order they were registered** — which is the order each feature's `register()` runs in
`AppComposition.bootstrapFeatures()`. The first mapper to return non-`nil` wins. If two mappers could plausibly match
the same URL, register the more specific one first.

## Checklist: wiring up a new feature

- [ ] Create the SPM package under `Packages/Features/<FeatureName>`, depending on `Navigation` (via
      `SharedLibraries`).
- [ ] Define `<FeatureName>Route: Route` with your screens.
- [ ] Build your views, reading `NavigationCoordinator` via `@EnvironmentObject`.
- [ ] *(Only if other features or deep links must reach in)* Add a `<FeatureName>API` product/target to your
      package's `Package.swift`, containing only a `public <FeatureName>Destination: NavigationDestination` with the
      cases meant to be externally reachable. Make your main target depend on it.
- [ ] *(Only if the above)* Write a `<FeatureName>DeepLinkMapper: DeepLinkMapper` in your main target, and register
      both it (`DeepLinkRouter.shared.register(...)`) and the destination (`RouteRegistry.shared.register(...)`)
      from your feature's own `register()`. This step is only needed if the feature must also be reachable by a
      *real* OS deep link — a destination only ever reached in-app from another feature doesn't need a mapper.
- [ ] *(Only if the above)* Make sure your feature's `register(...)` is actually called from
      `AppComposition.bootstrapFeatures()`.
- [ ] *(For a caller wanting to navigate in)* Add a dependency on the target feature's package and its
      `<FeatureName>API` product (never its main target), import it, and construct the destination directly —
      pick one direction only, since a two-way `API` dependency between features creates a circular package graph.
- [ ] Host the feature's root under a `NavigationHost` somewhere (a tab, a nav-linked entry point), with its own
      `NavigationCoordinator`.

A feature only needs the `<FeatureName>API` target if something *outside* the feature (another feature, a real deep
link) needs to reach into it; it only needs a `DeepLinkMapper` on top of that if a real URL must be able to resolve
to it too. A feature that's only ever navigated to internally can skip straight to hosting it.

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
- **`FeatureModule` exists in `Navigation` but isn't currently adopted.** Features register through a plain
  `register(network:)` static method on their own module enum (`FeatureYModule`, `FeatureXModule`), called directly
  from `AppComposition.bootstrapFeatures()` — not through a `[FeatureModule.Type]` array. If you want a uniform
  registration hook across features, conform to it; nothing currently depends on that happening.

## Testing

`Navigation` lives in the separate `SharedLibraries` package (pulled in via SPM) — there's no `Navigation` package
inside this repo. To run its test suite, `cd` into wherever `SharedLibraries` is checked out and:

```
swift test --filter NavigationTests
```

Runs on macOS directly — no simulator needed, finishes in well under a second. Coverage lives in
`Tests/NavigationTests`: `NavigationCoordinatorTests`, `RouteRegistryTests`, `AnyRouteTests`, `DeepLinkRouterTests`,
and `URLQueryItemTests`.

For this repo's own feature-level coverage — e.g. `FeatureYDeepLinkMapperTests`, which pins the exact URL shape a
real OS deep link into `FeatureY` must have — run the package's own test target, since the app scheme itself isn't
currently wired for the test action:

```
xcodebuild test -scheme FeatureY -destination 'platform=iOS Simulator,name=<simulator name>'
```
