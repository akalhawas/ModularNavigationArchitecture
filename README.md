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
| `NavigationDestination` | `Navigation` (protocol) | A small, feature-owned allowlist of entry points reachable from outside that feature. Declared **inside** the feature's own target and kept `internal` — not a separate shared package. |
| `RouteRegistry` | `Navigation` | Resolves a `NavigationDestination` into a real `AnyRoute`, without the caller knowing the feature's route type. |
| `DeepLinkMapper` / `DeepLinkRouter` | `Navigation` | Turns a `URL` into a `NavigationDestination`. `DeepLinkRouter.shared` is a singleton; each feature registers its own mapper into it at startup, the same way it registers with `RouteRegistry.shared`. |

The flows in one line each:

- **Internal:** `View` → `coordinator.navigate(to: SomeRoute.case)` → pushed onto `NavigationCoordinator.routes` → rendered by `NavigationHost`'s `NavigationStack`.
- **Cross-feature / deep link:** `URL` → `DeepLinkRouter.shared.resolve(url:)` (tries each registered `DeepLinkMapper` in order) → `NavigationDestination` → `RouteRegistry.shared.resolve(_:)` → `AnyRoute` → `coordinator.navigate(to:)`.

Because each feature's `NavigationDestination` type stays `internal`, nothing outside that feature can construct one
directly — a `URL` is the *only* thing that can cross a feature boundary. That means cross-feature navigation and a
real deep link (a link opened from Safari, Messages, a push notification) aren't two related mechanisms, they're the
*same* mechanism: a button in one feature that wants to jump into another feature builds a `URL` locally (nothing
goes over the network) and resolves it through the exact same pipeline the OS uses for a real deep link.

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
both directions and defeats the point of splitting features into packages. In this repo, `Colors` and `Users` share
no dependency at all in either direction — `ColorsView` reaches into `Users` purely through a `URL`.

### Step 1 — Declare the destination(s) your feature exposes, inside your own target

```swift
// Packages/Features/Users/Sources/Users/Presentation/Routing/UsersDestination.swift
import Navigation

/// Entry points into the Users feature reachable via UsersDeepLinkMapper and
/// registered with RouteRegistry. Kept internal and deliberately minimal.
enum UsersDestination: NavigationDestination {
    case details(id: Int)
}
```

Keep this to *only* the cases meant to be reachable from outside — it does not need to mirror your feature's `Route`
type. `UsersRoute` also has a `.usersList` case with no `UsersDestination` counterpart, on purpose: nobody should be
able to jump straight to "the list" from outside the feature. Adding a case here is a deliberate, visible step —
that's what keeps the external surface intentional instead of accidental.

### Step 2 — Write a mapper, and register both it and the destination from your own module

```swift
// Packages/Features/Users/Sources/Users/Presentation/Routing/UsersDeepLinkMapper.swift
import Navigation

struct UsersDeepLinkMapper: DeepLinkMapper {
    // xcrun simctl openurl booted "com.ali.modularnavigationexample://users/details?id=1"
    func map(url: URL) -> (any NavigationDestination)? {
        guard url.host == "users", url.path == "/details",
              let id = url.queryItem("id") else { return nil }
        return UsersDestination.details(id: Int(id) ?? 0)
    }
}
```

```swift
// Packages/Features/Users/Sources/Users/Dependencies/UsersModule.swift
public enum UsersModule {
    public static func register(network: NetworkService) {
        // ... build dependencies ...
        registerPublicEntryPoint()
    }

    private static func registerPublicEntryPoint() {
        RouteRegistry.shared.register(UsersDestination.self) { destination in
            switch destination {
            case .details(let id):
                return AnyRoute(UsersRoute.userDetail(id: id))
            }
        }
        DeepLinkRouter.shared.register(UsersDeepLinkMapper())
    }
}
```

`UsersModule.register(network:)` is called once at app launch from `AppComposition.bootstrapFeatures()` — see
`App/AppComposition.swift`. There's no central place that assembles a list of every feature's mapper; each feature
registers its own into the shared `DeepLinkRouter.shared`/`RouteRegistry.shared` singletons.

### Step 3 — Navigate in from anywhere, using only a URL + `Navigation`

```swift
// Packages/Features/Colors/Sources/Colors/Presentation/View/ColorsView.swift
Button {
    guard let url = URL(string: "com.ali.modularnavigationexample://users/details?id=1"),
          let destination = DeepLinkRouter.shared.resolve(url: url),
          let route = RouteRegistry.shared.resolve(destination) else { return }
    coordinator.navigate(to: route)
} label: { /* ... */ }
```

`ColorsView` never imports `Users` — it only knows `Navigation` and a URL string. If `Users` ever changes its
internal route shape, `UsersDestination` and `UsersDeepLinkMapper` are the only things that need to change; every
caller keeps working unmodified. (This exact URL string is also the one thing standing between "typo" and "silent
no-op" — see [`UsersDeepLinkMapperTests`](Packages/Features/Users/Tests/UsersTests/Presentation/Routing/UsersDeepLinkMapperTests.swift),
which pins it against regressions.)

## 3. Deep linking (from the OS)

This is the *same pipeline* as §2 — the only difference is where the `URL` comes from: the OS hands it to you via
`.onOpenURL` instead of a button constructing it locally.

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
    guard let route = RouteRegistry.shared.resolve(destination) else { return }
    selectedTab = .services
    servicesCoordinator.dismissSheet()
    servicesCoordinator.dismissFullScreen()
    servicesCoordinator.navigate(to: route, strategy: .push)
}
```

Deciding *where* to land (which tab, which coordinator) has to happen at this top level — a deep link can arrive
while the user is anywhere in the app. `.resetStack`/`.push` here is a per-app call; this example always pushes onto
the `services` tab's stack.

Mappers are tried **in the order they were registered** — which is the order each feature's `register()` runs in
`AppComposition.bootstrapFeatures()`. The first mapper to return non-`nil` wins. If two mappers could plausibly match
the same URL, register the more specific one first.

## Checklist: wiring up a new feature

- [ ] Create the SPM package under `Packages/Features/<FeatureName>`, depending on `Navigation` (via
      `SharedLibraries`).
- [ ] Define `<FeatureName>Route: Route` with your screens.
- [ ] Build your views, reading `NavigationCoordinator` via `@EnvironmentObject`.
- [ ] *(Only if other features or deep links must reach in)* Add a small, `internal`
      `<FeatureName>Destination: NavigationDestination` inside your own target — only the cases meant to be
      externally reachable.
- [ ] *(Only if the above)* Write a `<FeatureName>DeepLinkMapper: DeepLinkMapper`, and register both it
      (`DeepLinkRouter.shared.register(...)`) and the destination (`RouteRegistry.shared.register(...)`) from your
      feature's own `register()`.
- [ ] *(Only if the above)* Make sure your feature's `register(...)` is actually called from
      `AppComposition.bootstrapFeatures()`.
- [ ] Host the feature's root under a `NavigationHost` somewhere (a tab, a nav-linked entry point), with its own
      `NavigationCoordinator`.

A feature only needs the destination/mapper steps if something *outside* the feature (another feature, a real deep
link) needs to reach into it. A feature that's only ever navigated to internally can skip straight to hosting it.

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
  `register(network:)` static method on their own module enum (`UsersModule`, `ColorsModule`), called directly from
  `AppComposition.bootstrapFeatures()` — not through a `[FeatureModule.Type]` array. If you want a uniform
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

For this repo's own feature-level coverage — e.g. `UsersDeepLinkMapperTests`, which pins the exact deep-link URL
`ColorsView` depends on — run the package's own test target, since the app scheme itself isn't currently wired for
the test action:

```
xcodebuild test -scheme Users -destination 'platform=iOS Simulator,name=<simulator name>'
```
