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

This creates a real SPM package dependency from `Colors` → `Users` (`Colors/Package.swift` depends on `../Users`), and `ColorsView` directly names `UsersDestination`. Two features can never depend on each other simultaneously (SPM won't resolve a cycle), so today's model only works one-directionally and still leaves the calling feature aware of the target feature's existence and destination shape. Additionally, each feature registers its own destination with `RouteRegistry`/`DeepLinkRouter` from inside its own module — routing knowledge is spread across every feature instead of living in one place.

## Goal

No feature package may depend on another feature's package, directly or indirectly, and no feature's code may name or construct another feature's `NavigationDestination`/`Route`. Beyond that: a feature should not need to know `NavigationDestination`, `RouteRegistry`, or `DeepLinkRouter` exist at all — those are App-level routing concerns, not feature concerns. A feature only ever declares, in its own vocabulary, that "something happens" when a button is tapped; the App decides what that something is, and the App alone owns how any destination (its own feature's or another's) resolves to a screen.

## Design

### 1. Destinations live inside the App target — no new package

`ColorsDestination` and `UsersDestination` move to plain Swift files inside the App target itself:

```
App/
  Destinations/
    ColorsDestination.swift
    UsersDestination.swift
  Routing/
    ColorsDeepLinkMapper.swift
    UsersDeepLinkMapper.swift
  AppComposition.swift
  MainCoordinator.swift
```

Nothing outside `App` ever imports these types — no feature needs them, so there's no reason to package them separately. This replaces the earlier `ColorsAPI`/`UsersAPI` targets (and an earlier draft of this spec that introduced a shared `Packages/Destinations` package) with something simpler: the App target just owns this code directly.

```swift
// App/Destinations/UsersDestination.swift
import Navigation

public enum UsersDestination: NavigationDestination {
    case details(id: Int, onDetailAction: ActionCallback<Void>? = nil)

    public static func details(id: Int, onDetailAction: @escaping () -> Void) -> UsersDestination {
        .details(id: id, onDetailAction: ActionCallback(onDetailAction))
    }
}
```

### 2. Feature packages drop all Navigation-registry involvement

`Colors/Package.swift` and `Users/Package.swift` depend on only `Navigation` (for `Route`, `NavigationCoordinator`) and `NetworkService` — nothing else. `ColorsRoute`/`UsersRoute` stay `public` (the App needs them to build `AnyRoute` values), but `ColorsModule`/`UsersModule` drop `registerPublicEntryPoint()` entirely:

```swift
// ColorsModule.swift — after
@MainActor
public enum ColorsModule {
    static var viewModels: () -> ColorsViewModels = {
        fatalError("ColorsModule not registered — call ColorsModule.register(network:crossFeatureActions:) at app launch")
    }

    public static func register(network: NetworkService, crossFeatureActions: ColorsCrossFeatureActions) {
        let dependencies = ColorsDependencies(network: network, crossFeatureActions: crossFeatureActions)
        viewModels = { dependencies.viewModels }
    }
}
```

No `RouteRegistry`, no `DeepLinkRouter`, no `NavigationDestination` — not even for `Colors`' own destination — appears anywhere inside the `Colors` or `Users` packages.

### 3. Deep-link mappers move into the App target too

`ColorsDeepLinkMapper`/`UsersDeepLinkMapper` relocate to `App/Routing/`, next to the `Destination` types they produce:

```swift
// App/Routing/ColorsDeepLinkMapper.swift
import Navigation

struct ColorsDeepLinkMapper: DeepLinkMapper {
    // xcrun simctl openurl booted "com.ali.modularnavigationexample://colors/details?id=1"
    func map(url: URL) -> (any NavigationDestination)? {
        guard url.host == "colors", url.path == "/details", let id = url.queryItem("id")
        else { return nil }
        return ColorsDestination.details(id: Int(id) ?? 0)
    }
}
```

### 4. `MainCoordinator` handles cross-feature behavior; `AppComposition` registers

`MainCoordinator` already owns the app's coordinator state (`homeCoordinator`, `servicesCoordinator`) and already handles deep-link dispatch (`handleDeepLinkNavigation`). It's the natural home for *behavior* — what a cross-feature tap actually does — while `AppComposition` stays a one-time bootstrap step that registers destinations/mappers and wires `MainCoordinator`'s methods into each feature's DI:

```swift
// App/MainCoordinator.swift
extension MainCoordinator {
    func handleColorsSecondaryAction(coordinator: NavigationCoordinator, id: Int, onReturn: @escaping () -> Void) {
        guard let route = RouteRegistry.shared.resolve(
            UsersDestination.details(id: id, onDetailAction: onReturn)
        ) else { return }
        coordinator.navigate(to: route)
    }
}
```

```swift
// App/AppComposition.swift
@MainActor
enum AppComposition {
    static func bootstrapFeatures(mainCoordinator: MainCoordinator) {
        UsersModule.register(network: AppDependencies.shared.networkService)
        registerUsersRouting()

        ColorsModule.register(
            network: AppDependencies.shared.networkService,
            crossFeatureActions: ColorsCrossFeatureActions(
                onSecondaryAction: mainCoordinator.handleColorsSecondaryAction
            )
        )
        registerColorsRouting()
    }

    private static func registerColorsRouting() {
        RouteRegistry.shared.register(ColorsDestination.self) { destination in
            switch destination {
            case .details(let id): return AnyRoute(ColorsRoute.colorDetail(id: id))
            }
        }
        DeepLinkRouter.shared.register(ColorsDeepLinkMapper())
    }

    private static func registerUsersRouting() {
        RouteRegistry.shared.register(UsersDestination.self) { destination in
            switch destination {
            case .details(let id, let onDetailAction): return AnyRoute(UsersRoute.userDetail(id: id, onDetailAction: onDetailAction))
            }
        }
        DeepLinkRouter.shared.register(UsersDeepLinkMapper())
    }
}
```

```swift
// App/ModularNavigationExampleApp.swift
init() {
    AppComposition.bootstrapFeatures(mainCoordinator: mainCoordinator)
}
```

The registration mapping logic itself is the same each feature's module used to run — relocated wholesale into `AppComposition`, not rewritten. `AppComposition` is the only file that imports every feature's `Route` type and every `Destination` type together, because it's the only place that needs to. `MainCoordinator` is the only place cross-feature *behavior* lives, extending the same role it already plays for deep links.

### 5. Cross-feature trigger — unchanged from the prior draft

The seam a feature exposes for App-mediated navigation stays a struct of closures the feature defines in its own vocabulary:

```swift
// Packages/Features/Colors/Sources/Colors/Dependencies/ColorsCrossFeatureActions.swift
import Navigation

public struct ColorsCrossFeatureActions {
    public let onSecondaryAction: (NavigationCoordinator, Int, @escaping () -> Void) -> Void
    public init(onSecondaryAction: @escaping (NavigationCoordinator, Int, @escaping () -> Void) -> Void) {
        self.onSecondaryAction = onSecondaryAction
    }
}
```

Threaded through `ColorsDependencies` → `ColorsViewModels` → `ColorsViewModel` → `ColorsView`'s button, exactly as in the prior draft. Every identifier inside `Colors` describes Colors' own concern (`onSecondaryAction`, `didReturnFromSecondaryAction`) — never the word "user."

### 6. Net package graph

```
Colors  → Navigation, NetworkService
Users   → Navigation, NetworkService
App     → Colors, Users, Navigation, NetworkService
          (+ owns Destinations/DeepLinkMappers/registration as its own files — no separate package)
```

`Colors` and `Users` share zero dependency, and neither imports anything beyond `Navigation`/`NetworkService`. `App` is the only target that knows destinations, deep links, or routing exist.

## Error handling

Unchanged from the prior draft: `RouteRegistry.shared.resolve`'s existing trap-in-Debug/nil-in-Release behavior for an unregistered destination is untouched. `crossFeatureActions`' route resolution failing silently no-ops the button tap, matching current behavior.

## Testing

- `ColorsModule`/`ColorsDependencies`/`ColorsViewModel` tests now need **no** `Navigation`-registry stub at all, since registration isn't a feature concern anymore — only `ColorsCrossFeatureActions` needs a stub closure.
- `ColorsDeepLinkMapperTests`/`UsersDeepLinkMapperTests` move to the App target (or a new `AppTests` target) — they now test `App/Routing/*` files rather than feature-package files. This is a real relocation, not just an import change.
- Manual/integration check: tapping "Users" from Colors still navigates to Users' detail screen and still fires the return callback; deep links into either feature's screens still resolve.

## Out of scope

- No change to `Navigation`'s public API (`Route`, `NavigationCoordinator`, `RouteRegistry`, `DeepLinkRouter`, `ActionCallback`).
- No change to `ServicesView`'s direct `coordinator.navigate(to: UsersRoute.usersList)` / `ColorsRoute.colorsList)` calls — those already work the way this design wants (App owning the call, feature owning the route).
- `README.md`'s "Cross-feature navigation" and "Deep linking" sections both need a full rewrite — deep linking is no longer something a feature's checklist item sets up for itself; it's entirely an App-level concern now. Tracked as part of implementation, not a design decision.
