# App-owned cross-feature navigation

## Problem

Today, cross-feature navigation works by having the *calling* feature depend on the *target* feature's small `<FeatureName>API` product (e.g. `Colors` depends on `Users`' `UsersAPI` product), construct the target's `NavigationDestination` directly, and resolve+navigate itself:

```swift
// Packages/Features/Colors/Sources/Colors/Presentation/View/ColorsView.swift
import UsersAPI

let destination = UsersDestination.details(id: 1) { viewModel.didReturnFromUsers() }
guard let route = RouteRegistry.shared.resolve(destination) else { return }
coordinator.navigate(to: route)
```

This creates a real SPM package dependency from `Colors` → `Users` (`Colors/Package.swift` depends on `../Users`), and `ColorsView` directly names `UsersDestination`. Two features can never depend on each other simultaneously (SPM won't resolve a cycle), so today's model only works one-directionally and still leaves the calling feature aware of the target feature's existence and destination shape.

## Goal

No feature package may depend on another feature's package, directly or indirectly, and no feature's code may name or construct another feature's `NavigationDestination`/`Route`. Cross-feature navigation — which feature, which destination, how to resolve and navigate — becomes the App's responsibility exclusively. A feature only ever declares, in its own vocabulary, that "something happens" when a button is tapped; the App decides what that something is.

## Design

### 1. New local package: `Packages/Destinations`

A new SPM package, local to this repo (not published to the external `SharedLibraries` repo), holding every feature's own `NavigationDestination` enum in one place:

```
Packages/Destinations/
  Package.swift
  Sources/Destinations/
    ColorsDestination.swift
    UsersDestination.swift
```

```swift
// Packages/Destinations/Package.swift
let package = Package(
    name: "Destinations",
    platforms: [.iOS(.v16)],
    products: [.library(name: "Destinations", targets: ["Destinations"])],
    dependencies: [
        .package(url: "https://github.com/akalhawas/SharedLibraries.git", from: "0.1.4"),
    ],
    targets: [
        .target(name: "Destinations", dependencies: [.product(name: "Navigation", package: "SharedLibraries")]),
    ]
)
```

This package replaces the `ColorsAPI`/`UsersAPI` targets. It depends only on `Navigation`. Each feature depends on it **only to declare and register its own destination case** — never to construct another feature's.

### 2. Feature packages depend on nothing feature-related

`Colors/Package.swift` drops its `.package(path: "../Users")` dependency and the `ColorsAPI` target/product entirely. Both `Colors` and `Users` add a dependency on `../Destinations`:

```swift
// Packages/Features/Colors/Package.swift
dependencies: [
    .package(url: "https://github.com/akalhawas/SharedLibraries.git", from: "0.1.4"),
    .package(path: "../../Destinations"),
],
targets: [
    .target(
        name: "Colors",
        dependencies: [
            .product(name: "Navigation", package: "SharedLibraries"),
            .product(name: "NetworkService", package: "SharedLibraries"),
            .product(name: "Destinations", package: "Destinations"),
        ]
    ),
    // ...
]
```

`Users/Package.swift` gets the equivalent change (it already has no inter-feature dependency, so this is just swapping `UsersAPI` for `Destinations`).

After this, `Colors` and `Users` share zero SPM dependency edge between them.

### 3. Self-registration is unchanged in spirit

`ColorsModule`/`UsersModule` keep registering their own destination with `RouteRegistry.shared` and their own mapper with `DeepLinkRouter.shared`, exactly as today — only the import source changes (`Destinations` instead of the old `<Feature>API` target):

```swift
// ColorsModule.swift
import Destinations

RouteRegistry.shared.register(ColorsDestination.self) { destination in
    switch destination {
    case .details(let id): return AnyRoute(ColorsRoute.colorDetail(id: id))
    }
}
DeepLinkRouter.shared.register(ColorsDeepLinkMapper())
```

This is legitimate — a feature declaring and registering its *own* contract, not referencing another feature.

### 4. Cross-feature trigger: App-supplied closure via `ColorsModule.register`

The one call site that today reaches across features — `ColorsView`'s "Users" button — can no longer construct `UsersDestination`. Instead, `ColorsModule.register` grows a closure parameter that Colors defines in its own terms (what it needs, not who it goes to):

```swift
// ColorsModule.swift
public static func register(
    network: NetworkService,
    crossFeatureAction: @escaping (NavigationCoordinator, Int, @escaping () -> Void) -> Void
) {
    let dependencies = ColorsDependencies(network: network, crossFeatureAction: crossFeatureAction)
    viewModels = { dependencies.viewModels }
    registerPublicEntryPoint()
}
```

The closure is threaded through unchanged: `ColorsDependencies` stores it, `ColorsViewModels` passes it to `ColorsViewModel`'s init, `ColorsViewModel` exposes it (or the view reads it via the view model) for `ColorsView`'s button:

```swift
// ColorsView.swift — no import of Destinations, UsersAPI, or anything Users-related
Button {
    viewModel.crossFeatureAction(coordinator, 1) { viewModel.didReturnFromUsers() }
} label: { Text("Users")... }
```

`Colors` now only imports `Navigation` (for `NavigationCoordinator`, `Route`) and its own `Destinations` entry. It never sees `UsersDestination`, `UsersRoute`, `RouteRegistry`, or `AnyRoute` at this call site.

### 5. App builds the real implementation

`App/AppComposition.swift` is the only place in the app that imports `Destinations` for *both* features' cases and knows that Colors' button leads to Users:

```swift
// App/AppComposition.swift
import Destinations

@MainActor
enum AppComposition {
    static func bootstrapFeatures() {
        UsersModule.register(network: AppDependencies.shared.networkService)
        ColorsModule.register(
            network: AppDependencies.shared.networkService,
            crossFeatureAction: { coordinator, id, onReturn in
                guard let route = RouteRegistry.shared.resolve(
                    UsersDestination.details(id: id, onDetailAction: onReturn)
                ) else { return }
                coordinator.navigate(to: route)
            }
        )
    }
}
```

The closure receives the `NavigationCoordinator` from the call site (Colors' own `@EnvironmentObject`), so it navigates on whatever stack is actually hosting Colors at the time — preserving today's dynamic-coordinator behavior. `AppComposition` resolves via the same `RouteRegistry` used for deep links, so there's one resolution path, not two.

### 6. Deep linking is unaffected

Each feature's own `DeepLinkMapper` still maps a URL to its own destination (`ColorsDeepLinkMapper` → `ColorsDestination`, `UsersDeepLinkMapper` → `UsersDestination`), registered from the feature's own module. `MainCoordinator.handleDeepLinkNavigation` still resolves via `RouteRegistry.shared` and picks the tab/coordinator. This path was already app-mediated (a deep link can land on any tab); nothing here changes.

## Error handling

No new failure modes. `RouteRegistry.shared.resolve` keeps its existing trap-in-Debug/nil-in-Release behavior for an unregistered destination — unchanged, since resolution still goes through the same registry. If `crossFeatureAction`'s route resolution fails (e.g. registration order bug), the closure silently no-ops today (`guard ... else { return }`), matching the existing button's behavior before this change.

## Testing

- `ColorsModule`/`ColorsDependencies`/`ColorsViewModel` tests pass a stub `crossFeatureAction` closure (e.g. one that records whether it was called) instead of needing any Users-related target — this is strictly less coupled than today, since `ColorsTests` doesn't currently depend on `UsersAPI` either way.
- `ColorsDeepLinkMapperTests`/`UsersDeepLinkMapperTests` are unaffected — they test URL → own-`Destination` mapping, which doesn't change.
- New: a small `DestinationsTests` target is optional (the package holds only data, no logic) — not required.
- Manual/integration check: tapping "Users" from Colors still navigates to Users' detail screen and still fires `didReturnFromUsers()` when the detail screen's action happens, matching current behavior.

## Out of scope

- No change to `Navigation`'s public API (`Route`, `NavigationCoordinator`, `RouteRegistry`, `DeepLinkRouter`, `ActionCallback`) — all changes are local to this repo (`App/`, `Packages/Features/*`, new `Packages/Destinations`).
- No change to `ServicesView`'s direct `coordinator.navigate(to: UsersRoute.usersList)` / `ColorsRoute.colorsList)` calls — those are App-level entry points into a feature's own root, not cross-feature navigation, and already work the way this design wants (App owning the call, feature owning the route).
- `README.md`'s "2. Cross-feature navigation" section needs a full rewrite to document this pattern instead of the `<FeatureName>API` pattern — tracked as part of implementation, not a design decision.
