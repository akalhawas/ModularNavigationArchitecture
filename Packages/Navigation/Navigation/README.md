# Navigation

A small, dependency-free SwiftUI navigation layer built on `NavigationStack(path:)`. It gives every feature the same
toolkit for push/pop/present, and gives the app a way to let features navigate into *each other* without any feature
depending on another feature's implementation.

Three things this package is designed to make easy, and which this document covers in order:

1. **Internal navigation** — moving around inside a single feature.
2. **Cross-feature navigation** — feature A sending the user into feature B without importing it.
3. **Deep linking** — a URL landing the user on a specific screen, reusing the exact same mechanism as #2.

## Contents

- [Core concepts](#core-concepts)
- [1. Internal navigation](#1-internal-navigation-within-a-single-feature)
- [2. Cross-feature navigation](#2-cross-feature-navigation)
- [3. Deep linking](#3-deep-linking)
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
| `NavigationDestination` | `Navigation` (protocol) | A feature's *public* entry points — what other features/deep links are allowed to target. |
| `RouteRegistry` | `Navigation` | Resolves a `NavigationDestination` into a real `AnyRoute`, without the caller knowing the feature's route type. |
| `FeatureModule` | `Navigation` (protocol) | A feature's registration hook, called once at app startup. |
| `DeepLinkMapper` / `DeepLinkRouter` | `Navigation` | Turns an incoming `URL` into a `NavigationDestination`. |

The three flows in one line each:

- **Internal:** `View` → `coordinator.navigate(to: SomeRoute.case)` → pushed onto `NavigationCoordinator.routes` → rendered by `NavigationHost`'s `NavigationStack`.
- **Cross-feature:** `View` in Feature A → `FeatureBDestination.case` → `RouteRegistry.shared.resolve(_:)` → `AnyRoute` → `coordinator.navigate(to:)`.
- **Deep link:** `URL` → `DeepLinkRouter.resolve(url:)` (tries each `DeepLinkMapper` in order) → `NavigationDestination` → same `RouteRegistry.resolve(_:)` as above.

Cross-feature navigation and deep linking both bottom out in the *same* `RouteRegistry` call — a deep link is just
another way of producing a `NavigationDestination`.

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

**Never import one feature package from another to navigate into it.** That creates a compile-time dependency in
both directions and defeats the point of splitting features into packages. Instead:

- A feature that wants to be reachable from *outside itself* declares its entry points as a `NavigationDestination`
  in the lightweight `NavigationDestinations` package (which depends only on `Navigation`, nothing else).
- The feature itself registers a mapping from those destinations to its real, internal `Route` type, once, at app
  startup.
- Any other code that wants to navigate in only ever depends on `NavigationDestinations` + `Navigation` — never on
  the target feature's implementation package.

### Step 1 — Declare the destination(s) your feature exposes

```swift
// Packages/NavigationDestinations/.../Sources/NavigationDestinations/Features/FeatureX/FeatureXDestination.swift
import Navigation

/// Public entry points into FeatureX. Used for cross-feature navigation and deep linking.
public enum FeatureXDestination: NavigationDestination {
    case main
    case detail(id: String)
}
```

Keep this minimal — just enough to identify the screen and any parameters it needs. (See
`FeatureBDetailParams.swift` for the pattern if a destination needs a larger payload than a couple of scalars.)

### Step 2 — Register the destination inside your feature, mapped to a real route

```swift
// FeatureX/Sources/FeatureX/Navigation/FeatureXModule.swift
import Navigation
import NavigationDestinations

public enum FeatureXModule: FeatureModule {
    @MainActor
    public static func register() {
        RouteRegistry.shared.register(FeatureXDestination.self) { destination in
            switch destination {
            case .main:
                return AnyRoute(FeatureXRoute.main)
            case .detail(let id):
                return AnyRoute(FeatureXRoute.detail(id: id))
            }
        }
    }
}
```

### Step 3 — Register the module at the composition root

```swift
// App/MainApp.swift
@MainActor
enum AppComposition {
    static let modules: [FeatureModule.Type] = [
        FeatureBModule.self,
        FeatureXModule.self, // ← add your feature here
    ]

    static func configure() {
        modules.forEach { $0.register() }
    }
}
```

`configure()` must run before anything calls `resolve(_:)` — the app does this synchronously in its `init()`, before
any view renders.

### Step 4 — Navigate in from anywhere that depends only on `NavigationDestinations`

```swift
import Navigation
import NavigationDestinations

Button("Open Feature X") {
    let destination = FeatureXDestination.main
    guard let route = RouteRegistry.shared.resolve(destination) else { return }
    coordinator.navigate(to: route)
}
```

`resolve(_:)` returns `nil` if the destination was never registered (see [Gotchas](#gotchas--design-notes) for why
that's a `guard let`, not a force-unwrap).

## 3. Deep linking

Deep links reuse the *exact same* `NavigationDestination` → `RouteRegistry` pipeline as cross-feature navigation. A
`DeepLinkMapper` just produces a `NavigationDestination` from a `URL` instead of from a button tap.

### Step 1 — Write a mapper for your feature

```swift
import Navigation
import NavigationDestinations

public struct FeatureXDeepLinkMapper: DeepLinkMapper {
    public init() {}

    // xcrun simctl openurl booted "com.yourapp://featureX/detail?id=123"
    public func map(url: URL) -> (any NavigationDestination)? {
        guard url.host == "featureX" else { return nil }

        switch url.path {
        case "/main":
            return FeatureXDestination.main
        case "/detail":
            guard let id = url.queryItem("id") else { return nil }
            return FeatureXDestination.detail(id: id)
        default:
            return nil
        }
    }
}
```

`URL.queryItem(_:)` is provided by `Navigation` for reading a single query parameter.

### Step 2 — Register the mapper at the composition root

```swift
public static let deepLinkRouter = DeepLinkRouter(
    mappers: [
        FeatureBDeepLinkMapper(),
        FeatureXDeepLinkMapper(),
    ]
)
```

Mappers are tried **in array order**; the first one to return non-`nil` wins. If two mappers could ever plausibly
match the same URL, put the more specific one first.

### Step 3 — Resolve incoming URLs in the app

```swift
.onOpenURL { url in
    guard let destination = AppComposition.deepLinkRouter.resolve(url: url) else { return }
    mainCoordinator.handleExternalNavigation(to: destination)
}
```

### Step 4 — Decide *where* to land, at the app/tab level

A deep link can arrive while the user is anywhere in the app, so routing which tab/coordinator handles it belongs at
the top, not inside the feature:

```swift
func handleExternalNavigation(to destination: any NavigationDestination) {
    switch destination {
    case is FeatureXDestination:
        guard let route = RouteRegistry.shared.resolve(destination) else { return }
        selectedTab = .featureX
        featureXCoordinator.navigate(to: route, strategy: .resetStack)
    default:
        break
    }
}
```

`.resetStack` is usually what you want here — it clears whatever the user had pushed and lands them directly on the
destination, rather than pushing on top of an unrelated stack.

## Checklist: wiring up a new feature

- [ ] Create the SPM package under `Packages/Features/<FeatureName>`, depending on `Navigation` (and
      `NavigationDestinations` if step 4+ apply).
- [ ] Define `<FeatureName>Route: Route` with your screens.
- [ ] Build your views, reading `NavigationCoordinator` via `@EnvironmentObject`.
- [ ] *(Only if other features or deep links must reach in)* Add a `<FeatureName>Destination: NavigationDestination`
      in `NavigationDestinations`.
- [ ] *(Only if the above)* Implement `<FeatureName>Module: FeatureModule`, mapping destinations → routes.
- [ ] *(Only if the above)* Add the module to `AppComposition.modules`.
- [ ] *(Only if you need deep links)* Implement a `DeepLinkMapper` and add it to `AppComposition.deepLinkRouter`.
- [ ] Host the feature's root under a `NavigationHost` somewhere (a tab, a nav-linked entry point), with its own
      `NavigationCoordinator`.

A feature only needs the `NavigationDestinations` steps if something *outside* the feature (another feature, a deep
link) needs to reach into it. A feature that's only ever navigated to internally can skip straight from step 3 to
hosting it.

## Gotchas & design notes

- **`RouteRegistry.shared` is a global singleton**, populated by `AppComposition.configure()` in the app's `init()`.
  Calling `resolve(_:)` before that has run will hit the miss path below. For unit tests, prefer creating a fresh
  `RouteRegistry()` instance rather than touching `.shared`, so tests don't leak registrations into each other.
- **`resolve(_:)` traps in Debug/test builds and returns `nil` in Release** when a destination was never registered
  (`assertionFailure` under the hood). This is intentional: Debug, CI, and test runs should catch a forgotten
  registration immediately and loudly; a shipped Release build should degrade to a no-op instead of crashing for a
  user. One consequence: **don't** write a unit test that calls `resolve` on an unregistered destination under a
  normal `swift test` run — it will abort the whole test process, not fail one test. If you need to verify the
  non-trapping Release behavior specifically, run `swift test -c release`.
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

## Testing

```
cd Packages/Navigation/Navigation
swift test
```

Runs on macOS directly — no simulator needed, finishes in well under a second. Coverage lives in
`Tests/NavigationTests`: `NavigationCoordinatorTests`, `RouteRegistryTests`, `AnyRouteTests`, `DeepLinkRouterTests`,
and `URLQueryItemTests`.
