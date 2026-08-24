# App-Owned Cross-Feature Navigation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove the direct SPM dependency between the `Colors` and `Users` feature packages, and move all destination/routing knowledge (destinations, deep-link mappers, `RouteRegistry`/`DeepLinkRouter` registration) out of the feature packages and into the App target, so features share zero package dependency and zero symbol reference.

**Architecture:** `Colors` and `Users` keep only their own `Route` (internal navigation) and business logic; they lose all `NavigationDestination`/`RouteRegistry`/`DeepLinkRouter` involvement, including for their own destination. `App/Destinations/` and `App/Routing/` (plain files in the existing Xcode `App` target — it's a `PBXFileSystemSynchronizedRootGroup`, so no project-file editing is needed to add files there) own every feature's destination type and deep-link mapper. `AppComposition` registers everything at bootstrap; `MainCoordinator` gains the behavior for Colors' one outbound cross-feature action, extending its existing deep-link-dispatch role. Colors exposes that one action as `ColorsCrossFeatureActions`, a struct of closures it defines in its own vocabulary (never naming `Users`), injected via `ColorsModule.register(network:crossFeatureActions:)`.

**Tech Stack:** Swift 6.2, SwiftUI, Swift Package Manager (local path packages + one remote package `SharedLibraries` for `Navigation`/`NetworkService`), XCTest run via `xcodebuild test -scheme <Package>-Package -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.5'` at the package level (plain `swift test` fails in this environment — `SharedLibraries`' `NetworkService` hits Combine-availability build errors under SwiftPM's default macOS deployment target; there is no Xcode unit test target for the `App` target itself, see Task 4's Testing note).

**Spec:** `docs/superpowers/specs/2026-08-24-app-owned-cross-feature-navigation-design.md`

## Global Constraints

- No feature package (`Colors`, `Users`) may depend on another feature's package, directly or indirectly.
- No feature's code may reference `NavigationDestination`, `RouteRegistry`, `DeepLinkRouter`, or another feature's `Route`/destination — not even for the feature's own destination.
- Every identifier a feature defines for its outbound cross-feature seam must describe the feature's own concern (e.g. `onSecondaryAction`, `didReturnFromSecondaryAction`) — never the name of the target feature.
- `App/Destinations/*` and `App/Routing/*` are plain Swift files in the existing `App` Xcode target — do not create a new SPM package for them (per spec §1).
- Package-level verification is `xcodebuild test -scheme Colors-Package -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.5'` (respectively `Users-Package`) run from inside `Packages/Features/Colors` or `Packages/Features/Users` — **not** `swift test`, which fails in this environment on a pre-existing `SharedLibraries` Combine-availability issue unrelated to this plan (confirmed during pre-flight: both packages pass 31/31 tests via the `xcodebuild` form). If `iPhone 16`/`OS=18.5` isn't available on the machine running this plan, substitute any installed simulator from `xcrun simctl list devices available`. Full-app verification is `xcodebuild build -scheme ModularNavigationExample -destination 'generic/platform=iOS Simulator'`.

---

## File Structure

**New files:**
- `App/Destinations/ColorsDestination.swift` — `ColorsDestination: NavigationDestination`, App-owned.
- `App/Destinations/UsersDestination.swift` — `UsersDestination: NavigationDestination`, App-owned.
- `App/Routing/ColorsDeepLinkMapper.swift` — URL → `ColorsDestination`, relocated from `Colors`.
- `App/Routing/UsersDeepLinkMapper.swift` — URL → `UsersDestination`, relocated from `Users`.
- `Packages/Features/Colors/Sources/Colors/Dependencies/ColorsCrossFeatureActions.swift` — the struct of closures Colors exposes for its one outbound cross-feature seam.

**Modified files:**
- `Packages/Features/Colors/Package.swift` — drop `ColorsAPI` product/target, drop the `../Users` path dependency.
- `Packages/Features/Users/Package.swift` — drop `UsersAPI` product/target.
- `Packages/Features/Colors/Sources/Colors/Dependencies/ColorsModule.swift` — drop registry involvement, accept `crossFeatureActions:`.
- `Packages/Features/Colors/Sources/Colors/Dependencies/ColorsDependencies.swift` — thread `crossFeatureActions` through.
- `Packages/Features/Colors/Sources/Colors/Dependencies/ColorsViewModels.swift` — thread `crossFeatureActions` through.
- `Packages/Features/Colors/Sources/Colors/Presentation/ViewModel/ColorsViewModel.swift` — store `crossFeatureActions`, rename `didReturnFromUsers()` → `didReturnFromSecondaryAction()`.
- `Packages/Features/Colors/Sources/Colors/Presentation/View/ColorsView.swift` — button calls `viewModel.crossFeatureActions.onSecondaryAction(...)`, drop `import UsersAPI`.
- `Packages/Features/Users/Sources/Users/Dependencies/UsersModule.swift` — drop registry involvement entirely.
- `App/AppComposition.swift` — full rewrite: registers every feature's destination/mapper, builds `ColorsCrossFeatureActions` from `MainCoordinator`.
- `App/MainCoordinator.swift` — add `handleColorsSecondaryAction(...)`.
- `App/ModularNavigationExampleApp.swift` — pass `mainCoordinator` into `bootstrapFeatures(mainCoordinator:)`.
- `Packages/Features/Colors/Tests/ColorsTests/ColorsViewModelTests.swift` — update `makeSUT` for the new initializer parameter.
- `README.md` — rewrite "2. Cross-feature navigation" and "3. Deep linking" sections, the checklist, and the `FeatureModule` gotcha note.

**Deleted files:**
- `Packages/Features/Colors/Sources/ColorsAPI/ColorsDestination.swift` (and the now-empty `ColorsAPI` source directory).
- `Packages/Features/Users/Sources/UsersAPI/UsersDestination.swift` (and the now-empty `UsersAPI` source directory).
- `Packages/Features/Colors/Sources/Colors/Presentation/Routing/ColorsDeepLinkMapper.swift`.
- `Packages/Features/Users/Sources/Users/Presentation/Routing/UsersDeepLinkMapper.swift`.
- `Packages/Features/Users/Tests/UsersTests/Presentation/Routing/UsersDeepLinkMapperTests.swift` (its coverage becomes a manual verification step in Task 4 — there is no App-level XCTest target to host an equivalent automated test; see Task 4's Testing note).

---

### Task 1: App-owned Destinations and DeepLinkMappers

**Files:**
- Create: `App/Destinations/ColorsDestination.swift`
- Create: `App/Destinations/UsersDestination.swift`
- Create: `App/Routing/ColorsDeepLinkMapper.swift`
- Create: `App/Routing/UsersDeepLinkMapper.swift`

**Interfaces:**
- Consumes: `Navigation`'s `NavigationDestination` protocol, `DeepLinkMapper` protocol, `ActionCallback<Void>`, `URL.queryItem(_:)` (all already available via `import Navigation`).
- Produces: `ColorsDestination.details(id: Int)`, `UsersDestination.details(id: Int, onDetailAction: ActionCallback<Void>?)` + the `onDetailAction: @escaping () -> Void` convenience overload, `ColorsDeepLinkMapper`, `UsersDeepLinkMapper` — all consumed by Task 4's `AppComposition`.

This task only adds new files; nothing references them yet, so it cannot break any existing build. `App` is a `PBXFileSystemSynchronizedRootGroup` in the Xcode project, so files placed under `App/Destinations/` and `App/Routing/` are picked up automatically — no `.pbxproj` editing is needed.

- [ ] **Step 1: Create the `App/Destinations` and `App/Routing` directories with the destination types**

`App/Destinations/ColorsDestination.swift`:
```swift
import Navigation

/// Defines public entry points into the Colors feature. Owned by the App,
/// not by Colors — Colors never imports or constructs this type itself.
public enum ColorsDestination: NavigationDestination {
    case details(id: Int)
}
```

`App/Destinations/UsersDestination.swift`:
```swift
import Navigation

/// Defines public entry points into the Users feature. Owned by the App,
/// not by Users — Users never imports or constructs this type itself.
public enum UsersDestination: NavigationDestination {
    /// - Parameter onDetailAction: Called by the Users detail screen's own
    ///   view model when its own action happens — independent of navigation
    ///   or pop timing. `nil` for anything that can't supply one, e.g. a
    ///   real OS deep link resolved from a URL.
    case details(id: Int, onDetailAction: ActionCallback<Void>? = nil)

    /// Convenience for callers that just want to pass a closure directly.
    public static func details(id: Int, onDetailAction: @escaping () -> Void) -> UsersDestination {
        .details(id: id, onDetailAction: ActionCallback(onDetailAction))
    }
}
```

- [ ] **Step 2: Create the deep-link mappers**

`App/Routing/ColorsDeepLinkMapper.swift`:
```swift
import Foundation
import Navigation

struct ColorsDeepLinkMapper: DeepLinkMapper {

    // xcrun simctl openurl booted "com.ali.modularnavigationexample://colors/details?id=1"

    func map(url: URL) -> (any NavigationDestination)? {
        guard url.host == "colors" else { return nil }

        switch url.path {
        case "/details":
            guard let id = url.queryItem("id").flatMap(Int.init) else { return nil }
            return ColorsDestination.details(id: id)
        default:
            return nil
        }
    }
}
```

`App/Routing/UsersDeepLinkMapper.swift`:
```swift
import Foundation
import Navigation

struct UsersDeepLinkMapper: DeepLinkMapper {

    // xcrun simctl openurl booted "com.ali.modularnavigationexample://users/details?id=1"

    func map(url: URL) -> (any NavigationDestination)? {
        if url.host == "users",
           url.path == "/details",
           let id = url.queryItem("id") {
            return UsersDestination.details(id: Int(id) ?? 0)
        }
        return nil
    }
}
```

- [ ] **Step 3: Verify the App target still builds**

Run: `xcodebuild build -scheme ModularNavigationExample -destination 'generic/platform=iOS Simulator' -project ModularNavigationExample.xcodeproj`
Expected: BUILD SUCCEEDED. These four new types don't collide with the old `ColorsAPI`/`UsersAPI`-owned ones (different modules), so the app still builds using the old cross-feature path — this task is purely additive.

- [ ] **Step 4: Commit**

```bash
git add App/Destinations App/Routing
git commit -m "$(cat <<'EOF'
[FEAT] Add App-owned Destinations and DeepLinkMappers

First step of moving cross-feature routing into the App target: these
new types aren't wired up to anything yet, so they're additive only.
EOF
)"
```

---

### Task 2: Colors exposes its cross-feature seam as `ColorsCrossFeatureActions`

**Files:**
- Create: `Packages/Features/Colors/Sources/Colors/Dependencies/ColorsCrossFeatureActions.swift`
- Modify: `Packages/Features/Colors/Sources/Colors/Dependencies/ColorsModule.swift`
- Modify: `Packages/Features/Colors/Sources/Colors/Dependencies/ColorsDependencies.swift`
- Modify: `Packages/Features/Colors/Sources/Colors/Dependencies/ColorsViewModels.swift`
- Modify: `Packages/Features/Colors/Sources/Colors/Presentation/ViewModel/ColorsViewModel.swift`
- Modify: `Packages/Features/Colors/Sources/Colors/Presentation/View/ColorsView.swift`
- Modify: `Packages/Features/Colors/Tests/ColorsTests/ColorsViewModelTests.swift`
- Test: `Packages/Features/Colors/Tests/ColorsTests/ColorsViewModelTests.swift`

**Interfaces:**
- Consumes: nothing from Task 1 (this task is entirely inside `Colors`).
- Produces: `ColorsCrossFeatureActions(onSecondaryAction: (NavigationCoordinator, Int, @escaping () -> Void) -> Void)`, `ColorsModule.register(network:crossFeatureActions:)` — both consumed by Task 4's `AppComposition`.

This task does not yet remove `ColorsAPI`/`UsersAPI` — `ColorsModule.registerPublicEntryPoint()` (which still uses `ColorsAPI`'s `ColorsDestination`) is untouched here, so `Colors` still builds and tests on its own after this task. Only the cross-feature button's call site changes.

- [ ] **Step 1: Write the failing test for the new `ColorsViewModel` initializer**

Replace the full contents of `Packages/Features/Colors/Tests/ColorsTests/ColorsViewModelTests.swift` with:

```swift
import XCTest
@testable import Colors
import Navigation

final class ColorsViewModelTests: XCTestCase {

    private func makeSUT(
        useCase: MockFetchColorsUseCase = MockFetchColorsUseCase(),
        crossFeatureActions: ColorsCrossFeatureActions = ColorsCrossFeatureActions(onSecondaryAction: { _, _, _ in })
    ) -> ColorsViewModel {
        ColorsViewModel(fetchColorsUseCase: useCase, crossFeatureActions: crossFeatureActions)
    }

    private static let mockColor = AppColor(
        id: 1,
        name: "Mock AppColor",
        year: 2026,
        color: "#98B2D1",
        pantoneValue: "15-4020"
    )

    private static let mockSupport = SupportInfo(url: "https://reqres.in/#support-heading", text: "Mock data")

    func testFetchColorsSuccessUpdatesColorsState() {
        // Arrange
        let useCase = MockFetchColorsUseCase()
        let response = ColorListResponse(
            page: 1,
            perPage: 6,
            total: 1,
            totalPages: 1,
            data: [Self.mockColor],
            support: Self.mockSupport
        )
        useCase.result = .success(response)
        let sut = makeSUT(useCase: useCase)

        // Act
        sut.fetchColors()

        // Assert
        XCTAssertEqual(sut.colors, [Self.mockColor])
        XCTAssertNil(sut.errorMessage)
    }

    func testFetchColorsFailureSetsErrorMessage() {
        // Arrange
        let useCase = MockFetchColorsUseCase()
        useCase.result = .failure(TestError.network)
        let sut = makeSUT(useCase: useCase)

        // Act
        sut.fetchColors()

        // Assert
        XCTAssertEqual(sut.errorMessage, TestError.network.errorDescription)
        XCTAssertTrue(sut.colors.isEmpty)
    }

    func testFetchColorsEmptyResponseClearsColors() {
        // Arrange
        let useCase = MockFetchColorsUseCase()
        let response = ColorListResponse(page: 1, perPage: 6, total: 0, totalPages: 0, data: [], support: Self.mockSupport)
        useCase.result = .success(response)
        let sut = makeSUT(useCase: useCase)

        // Act
        sut.fetchColors()

        // Assert
        XCTAssertTrue(sut.colors.isEmpty)
        XCTAssertNil(sut.errorMessage)
    }

    func testFetchColorsPassesRequestedPageToUseCase() {
        // Arrange
        let useCase = MockFetchColorsUseCase()
        useCase.result = .success(
            ColorListResponse(page: 3, perPage: 6, total: 1, totalPages: 1, data: [Self.mockColor], support: Self.mockSupport)
        )
        let sut = makeSUT(useCase: useCase)

        // Act
        sut.fetchColors(page: 3)

        // Assert
        XCTAssertEqual(useCase.lastPage, 3)
        XCTAssertEqual(useCase.executeCallCount, 1)
    }

    func testFetchColorsRepeatedCallsReplaceState() {
        // Arrange
        let useCase = MockFetchColorsUseCase()
        let sut = makeSUT(useCase: useCase)
        useCase.result = .failure(TestError.generic)

        // Act
        sut.fetchColors()
        useCase.result = .success(
            ColorListResponse(page: 1, perPage: 6, total: 1, totalPages: 1, data: [Self.mockColor], support: Self.mockSupport)
        )
        sut.fetchColors()

        // Assert
        XCTAssertEqual(sut.colors, [Self.mockColor])
        XCTAssertEqual(useCase.executeCallCount, 2)
    }

    func testExposesTheInjectedCrossFeatureActions() {
        // Arrange
        var capturedId: Int?
        let actions = ColorsCrossFeatureActions(onSecondaryAction: { _, id, _ in capturedId = id })
        let sut = makeSUT(crossFeatureActions: actions)

        // Act
        sut.crossFeatureActions.onSecondaryAction(NavigationCoordinator(), 7, {})

        // Assert
        XCTAssertEqual(capturedId, 7)
    }
}
```

Only `makeSUT`'s signature (adds the `crossFeatureActions` parameter with a no-op default) and the new `testExposesTheInjectedCrossFeatureActions` test are new — every other test body is unchanged from the current file.

- [ ] **Step 2: Run the test to verify it fails to compile**

Run (from `Packages/Features/Colors`): `xcodebuild test -scheme Colors-Package -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.5' -only-testing:ColorsTests/ColorsViewModelTests`
Expected: FAIL to build — `ColorsCrossFeatureActions` doesn't exist yet, and `ColorsViewModel.init` doesn't accept `crossFeatureActions:`.

- [ ] **Step 3: Create `ColorsCrossFeatureActions`**

```swift
// Packages/Features/Colors/Sources/Colors/Dependencies/ColorsCrossFeatureActions.swift
import Navigation

/// The one outbound cross-feature seam Colors exposes, named for what
/// Colors itself needs — not for whichever feature actually handles it.
/// The App supplies the real implementation at `ColorsModule.register`.
public struct ColorsCrossFeatureActions {
    public let onSecondaryAction: (NavigationCoordinator, Int, @escaping () -> Void) -> Void

    public init(onSecondaryAction: @escaping (NavigationCoordinator, Int, @escaping () -> Void) -> Void) {
        self.onSecondaryAction = onSecondaryAction
    }
}
```

- [ ] **Step 4: Thread `crossFeatureActions` through `ColorsViewModel`**

Edit `Packages/Features/Colors/Sources/Colors/Presentation/ViewModel/ColorsViewModel.swift`:

```swift
import Foundation
import Combine

final class ColorsViewModel: ObservableObject {

    @Published private(set) var colors: [AppColor] = []
    @Published private(set) var errorMessage: String?

    let crossFeatureActions: ColorsCrossFeatureActions

    private let fetchColorsUseCase: FetchColorsUseCase
    private var cancellables = Set<AnyCancellable>()

    init(fetchColorsUseCase: FetchColorsUseCase, crossFeatureActions: ColorsCrossFeatureActions) {
        self.fetchColorsUseCase = fetchColorsUseCase
        self.crossFeatureActions = crossFeatureActions
    }

    func fetchColors(page: Int = 1) {
        fetchColorsUseCase.execute(page: page)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] response in
                self?.colors = response.data
            }
            .store(in: &cancellables)
    }

    /// Called when the secondary-action screen this feature navigated into
    /// reports its own action happened. Fill in whatever Colors needs to do
    /// in response.
    func didReturnFromSecondaryAction() {
        print("DEBUG: didReturnFromSecondaryAction")
    }
}
```

- [ ] **Step 5: Thread `crossFeatureActions` through `ColorsViewModels` and `ColorsDependencies`**

Edit `Packages/Features/Colors/Sources/Colors/Dependencies/ColorsViewModels.swift`:

```swift
final class ColorsViewModels {

    private let useCases: ColorsUseCases
    private let crossFeatureActions: ColorsCrossFeatureActions

    init(useCases: ColorsUseCases, crossFeatureActions: ColorsCrossFeatureActions) {
        self.useCases = useCases
        self.crossFeatureActions = crossFeatureActions
    }

    @MainActor
    func makeColorsViewModel() -> ColorsViewModel {
        ColorsViewModel(fetchColorsUseCase: useCases.fetchColorsUseCase, crossFeatureActions: crossFeatureActions)
    }

    @MainActor
    func makeColorDetailViewModel(colorId: Int) -> ColorDetailViewModel {
        ColorDetailViewModel(colorId: colorId, fetchColorDetailUseCase: useCases.fetchColorDetailUseCase)
    }

    @MainActor
    func makeLatestColorsViewModel(limit: Int = 10) -> LatestColorsViewModel {
        LatestColorsViewModel(fetchColorsUseCase: useCases.fetchColorsUseCase, limit: limit)
    }
}
```

Edit `Packages/Features/Colors/Sources/Colors/Dependencies/ColorsDependencies.swift`:

```swift
import NetworkService

struct ColorsDependencies {

    let networkService: NetworkService
    let repositories: ColorsRepositories
    let useCases: ColorsUseCases
    let viewModels: ColorsViewModels

    init(network: NetworkService, crossFeatureActions: ColorsCrossFeatureActions) {
        self.networkService = network
        self.repositories = ColorsDependencies.createRepositories(networkService: network)
        self.useCases = ColorsUseCases(repositories: repositories)
        self.viewModels = ColorsViewModels(useCases: useCases, crossFeatureActions: crossFeatureActions)
    }

    private static func createRepositories(networkService: NetworkService) -> ColorsRepositories {
        #if LOCALDEBUG
        return MockRepositories()
        #else
        return Repositories(networkService: networkService)
        #endif
    }
}
```

- [ ] **Step 6: Update `ColorsModule.register` to accept `crossFeatureActions`**

Edit `Packages/Features/Colors/Sources/Colors/Dependencies/ColorsModule.swift` — change only the `register` signature and the `ColorsDependencies` call; leave `registerPublicEntryPoint()` untouched for now (Task 3 removes it):

```swift
import SwiftUI
import NetworkService
import Navigation
import ColorsAPI

@MainActor
public enum ColorsModule {

    static var viewModels: () -> ColorsViewModels = {
        fatalError("ColorsModule not registered — call ColorsModule.register(network:crossFeatureActions:) at app launch")
    }

    public static func register(network: NetworkService, crossFeatureActions: ColorsCrossFeatureActions) {
        let dependencies = ColorsDependencies(network: network, crossFeatureActions: crossFeatureActions)
        viewModels = { dependencies.viewModels }
        registerPublicEntryPoint()
    }

    static func registerPublicEntryPoint() {
        RouteRegistry.shared.register(ColorsDestination.self) { destination in
            switch destination {
            case .details(let id):
                return AnyRoute(ColorsRoute.colorDetail(id: id))
            }
        }
        DeepLinkRouter.shared.register(ColorsDeepLinkMapper())
    }
}
```

- [ ] **Step 7: Update `ColorsView`'s button to call the injected closure instead of constructing `UsersDestination`**

Edit `Packages/Features/Colors/Sources/Colors/Presentation/View/ColorsView.swift` — remove `import UsersAPI` and replace the button's action:

```swift
import SwiftUI
import Navigation

struct ColorsView: View {

    @StateObject private var viewModel: ColorsViewModel
    @EnvironmentObject var coordinator: NavigationCoordinator

    init(viewModel: ColorsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack {
            content
                .navigationTitle("Colors")
                .task {
                    if viewModel.colors.isEmpty {
                        viewModel.fetchColors()
                    }
                }

            Button {
                viewModel.crossFeatureActions.onSecondaryAction(coordinator, 1) {
                    viewModel.didReturnFromSecondaryAction()
                }
            } label: {
                Text("Users")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if let errorMessage = viewModel.errorMessage {
            ErrorStateView(message: errorMessage) {
                viewModel.fetchColors()
            }
        } else if viewModel.colors.isEmpty {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List(viewModel.colors) { color in
                Button {
                    coordinator.presentSheet(ColorsRoute.colorDetail(id: color.id))
                } label: {
                    ColorRow(color: color)
                }
                .buttonStyle(.plain)
            }
            .listStyle(.plain)
            .refreshable {
                viewModel.fetchColors()
            }
        }
    }
}
```

Leave the rest of the file (`ColorRow`, the `Color(hex:)` extension, the `#Preview`) untouched, except the `#Preview` block needs the new initializer argument:

```swift
#Preview {
    NavigationStack {
        ColorsView(
            viewModel: ColorsViewModel(
                fetchColorsUseCase: FetchColorsUseCaseImp(repository: ColorRepositoryMock()),
                crossFeatureActions: ColorsCrossFeatureActions(onSecondaryAction: { _, _, _ in })
            )
        )
    }
}
```

- [ ] **Step 8: Run the tests to verify they pass**

Run (from `Packages/Features/Colors`): `xcodebuild test -scheme Colors-Package -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.5' -only-testing:ColorsTests/ColorsViewModelTests`
Expected: PASS — all existing `ColorsViewModelTests` cases plus `testExposesTheInjectedCrossFeatureActions`.

- [ ] **Step 9: Run the full Colors package test suite**

Run (from `Packages/Features/Colors`): `xcodebuild test -scheme Colors-Package -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.5'`
Expected: PASS (31 tests, per the pre-flight baseline run). `Colors` still depends on `Users`/`ColorsAPI`/`UsersAPI` at this point (Task 3 removes that), so this should build and pass exactly as before, with the new cross-feature-actions behavior added.

- [ ] **Step 10: Commit**

```bash
git add Packages/Features/Colors
git commit -m "$(cat <<'EOF'
[REFACTOR] Route Colors' cross-feature button through an injected closure

ColorsView no longer constructs UsersDestination directly — it calls
viewModel.crossFeatureActions.onSecondaryAction, a closure ColorsModule
now requires at registration. ColorsAPI/UsersAPI are still in place;
removing them is the next step.
EOF
)"
```

---

### Task 3: Remove `ColorsAPI`/`UsersAPI` and all feature-owned registry code

**Files:**
- Modify: `Packages/Features/Colors/Package.swift`
- Modify: `Packages/Features/Users/Package.swift`
- Modify: `Packages/Features/Colors/Sources/Colors/Dependencies/ColorsModule.swift`
- Modify: `Packages/Features/Users/Sources/Users/Dependencies/UsersModule.swift`
- Delete: `Packages/Features/Colors/Sources/ColorsAPI/ColorsDestination.swift`
- Delete: `Packages/Features/Users/Sources/UsersAPI/UsersDestination.swift`
- Delete: `Packages/Features/Colors/Sources/Colors/Presentation/Routing/ColorsDeepLinkMapper.swift`
- Delete: `Packages/Features/Users/Sources/Users/Presentation/Routing/UsersDeepLinkMapper.swift`
- Delete: `Packages/Features/Users/Tests/UsersTests/Presentation/Routing/UsersDeepLinkMapperTests.swift`

**Interfaces:**
- Consumes: nothing new.
- Produces: `Colors` and `Users` packages that depend on only `Navigation` + `NetworkService`, with `ColorsModule.register(network:crossFeatureActions:)` and `UsersModule.register(network:)` doing DI wiring only — no `RouteRegistry`/`DeepLinkRouter` reference anywhere. Consumed by Task 4.

This is the task where the feature-to-feature dependency actually disappears from the package graph. After this task, `Colors` and `Users` will not build against each other or against `RouteRegistry`/`DeepLinkRouter` at all — but the `App` Xcode target will **not** build until Task 4 rewires `AppComposition`, since `AppComposition.bootstrapFeatures()` still calls the old one-argument `ColorsModule.register(network:)` and still relies on each feature to self-register. That's expected — this task's verification is at the package level (`xcodebuild test -scheme <Package>-Package ...`), not the app level.

- [ ] **Step 1: Remove `ColorsAPI`/`UsersAPI` from both `Package.swift` files**

`Packages/Features/Colors/Package.swift`:
```swift
// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Colors",
    platforms: [
        .iOS(.v16),
    ],
    products: [
        .library(name: "Colors", targets: ["Colors"]),
    ], dependencies: [
        .package(url: "https://github.com/akalhawas/SharedLibraries.git", from: "0.1.4"),
    ],
    targets: [
        .target(
            name: "Colors",
            dependencies: [
                .product(name: "Navigation", package: "SharedLibraries"),
                .product(name: "NetworkService", package: "SharedLibraries"),
            ]
        ),
        .testTarget(
            name: "ColorsTests",
            dependencies: [
                "Colors",
                .product(name: "NetworkService", package: "SharedLibraries"),
            ]
        ),
    ]
)
```

`Packages/Features/Users/Package.swift`:
```swift
// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Users",
    platforms: [
        .iOS(.v16),
    ],
    products: [
        .library(name: "Users", targets: ["Users"]),
    ], dependencies: [
        .package(url: "https://github.com/akalhawas/SharedLibraries.git", from: "0.1.4"),
    ],
    targets: [
        .target(
            name: "Users",
            dependencies: [
                .product(name: "Navigation", package: "SharedLibraries"),
                .product(name: "NetworkService", package: "SharedLibraries"),
            ]
        ),
        .testTarget(
            name: "UsersTests",
            dependencies: [
                "Users",
                .product(name: "NetworkService", package: "SharedLibraries"),
            ]
        ),
    ]
)
```

- [ ] **Step 2: Delete the `ColorsAPI`/`UsersAPI` source directories and the old deep-link mappers/tests**

```bash
rm -rf Packages/Features/Colors/Sources/ColorsAPI
rm -rf Packages/Features/Users/Sources/UsersAPI
rm Packages/Features/Colors/Sources/Colors/Presentation/Routing/ColorsDeepLinkMapper.swift
rm Packages/Features/Users/Sources/Users/Presentation/Routing/UsersDeepLinkMapper.swift
rm Packages/Features/Users/Tests/UsersTests/Presentation/Routing/UsersDeepLinkMapperTests.swift
```

- [ ] **Step 3: Strip `ColorsModule` down to DI wiring only**

```swift
// Packages/Features/Colors/Sources/Colors/Dependencies/ColorsModule.swift
import NetworkService

/// Resolves this feature's dependencies without callers having to build
/// `ColorsDependencies` themselves at every navigation site.
///
/// Must be configured once at app launch (see `AppComposition.bootstrapFeatures`)
/// before any `ColorsRoute` is navigated to.
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

- [ ] **Step 4: Strip `UsersModule` down to DI wiring only**

```swift
// Packages/Features/Users/Sources/Users/Dependencies/UsersModule.swift
import NetworkService

/// Resolves this feature's dependencies without callers having to build
/// `UsersDependencies` themselves at every navigation site.
///
/// Must be configured once at app launch (see `AppComposition.bootstrapFeatures`)
/// before any `UsersRoute` is navigated to.
@MainActor
public enum UsersModule {

    static var viewModels: () -> UsersViewModels = {
        fatalError("UsersModule has not been registered.")
    }

    public static func register(network: NetworkService) {
        let dependencies = UsersDependencies(network: network)
        viewModels = { dependencies.viewModels }
    }
}
```

- [ ] **Step 5: Run the Colors package test suite**

Run (from `Packages/Features/Colors`): `xcodebuild test -scheme Colors-Package -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.5'`
Expected: PASS. `Colors` now resolves with no dependency on `Users` at all.

- [ ] **Step 6: Run the Users package test suite**

Run (from `Packages/Features/Users`): `xcodebuild test -scheme Users-Package -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.5'`
Expected: PASS with 0 failures. The total test count will be lower than the pre-flight baseline's 31, since `UsersDeepLinkMapperTests` (4 tests) is deleted in Step 2 of this task — check for "0 failures", not a specific count. `UsersDeepLinkMapperTests` is gone (its coverage moves to Task 4's manual verification), and every remaining test passes.

- [ ] **Step 7: Confirm there is no remaining cross-reference**

Run: `grep -rn "ColorsAPI\|UsersAPI\|ColorsDestination\|UsersDestination" Packages/Features`
Expected: no output.

Run: `grep -n "Users" Packages/Features/Colors/Package.swift`
Expected: no output.

- [ ] **Step 8: Commit**

```bash
git add Packages/Features
git commit -m "$(cat <<'EOF'
[REFACTOR] Remove ColorsAPI/UsersAPI — features share zero dependency

Colors and Users no longer depend on each other, on each other's API
target, or on RouteRegistry/DeepLinkRouter for their own destination.
Both packages now depend on only Navigation + NetworkService. The App
target does not build again until AppComposition is rewired (next task).
EOF
)"
```

---

### Task 4: Wire up `AppComposition` and `MainCoordinator`

**Files:**
- Modify: `App/AppComposition.swift`
- Modify: `App/MainCoordinator.swift`
- Modify: `App/ModularNavigationExampleApp.swift`

**Interfaces:**
- Consumes: `ColorsDestination`/`UsersDestination`/`ColorsDeepLinkMapper`/`UsersDeepLinkMapper` (Task 1), `ColorsCrossFeatureActions`/`ColorsModule.register(network:crossFeatureActions:)` (Tasks 2–3), `UsersModule.register(network:)` (Task 3), `ColorsRoute`, `UsersRoute` (unchanged, already public).
- Produces: a fully wired app — this is the last task before the app builds and runs end-to-end again.

- [ ] **Step 1: Add the cross-feature behavior to `MainCoordinator`**

Edit `App/MainCoordinator.swift` — add a new extension below the existing `Feature Deeplink` one:

```swift
//
//  MainCoordinator.swift
//  ModularizedByFeature
//
//  Created by ali alhawas on 24/07/2026.
//

import Combine
import SwiftUI

@MainActor
final class MainCoordinator: ObservableObject {

    @Published var selectedTab: TabBar = .home
    @Published var isTabBarHidden: Bool = false

    let homeCoordinator = NavigationCoordinator()
    let servicesCoordinator = NavigationCoordinator()

    private var allCoordinators: [NavigationCoordinator] {
        [homeCoordinator, servicesCoordinator]
    }

    init() { }

}

// MARK: Feature Deeplink
extension MainCoordinator {
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
}

// MARK: Cross-feature navigation
extension MainCoordinator {
    /// Colors' one outbound cross-feature seam. Resolves to Users' detail
    /// screen and navigates on whichever coordinator Colors itself is
    /// hosted under — this is the only file in the app that knows Colors'
    /// button leads to Users.
    func handleColorsSecondaryAction(coordinator: NavigationCoordinator, id: Int, onReturn: @escaping () -> Void) {
        guard let route = RouteRegistry.shared.resolve(
            UsersDestination.details(id: id, onDetailAction: onReturn)
        ) else { return }
        coordinator.navigate(to: route)
    }
}
```

- [ ] **Step 2: Rewrite `AppComposition`**

```swift
//
//  AppComposition.swift
//  ModularizedByFeature
//
//  Created by ali alhawas on 24/07/2026.
//

import SwiftUI

@MainActor
enum AppComposition {
    // MARK: Register new feature
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
            case .details(let id):
                return AnyRoute(ColorsRoute.colorDetail(id: id))
            }
        }
        DeepLinkRouter.shared.register(ColorsDeepLinkMapper())
    }

    private static func registerUsersRouting() {
        RouteRegistry.shared.register(UsersDestination.self) { destination in
            switch destination {
            case .details(let id, let onDetailAction):
                return AnyRoute(UsersRoute.userDetail(id: id, onDetailAction: onDetailAction))
            }
        }
        DeepLinkRouter.shared.register(UsersDeepLinkMapper())
    }
}
```

- [ ] **Step 3: Update the app entry point to pass `mainCoordinator` in**

Edit `App/ModularNavigationExampleApp.swift`:

```swift
//
//  ModularNavigationExampleApp.swift
//  ModularNavigationExample
//
//  Created by ali alhawas on 10/07/2026.
//

import SwiftUI
import Combine
@_exported import Users
@_exported import Colors
@_exported import Navigation

@main
struct ModularizedByFeatureApp: App {

    @StateObject var mainCoordinator = MainCoordinator()

    init() {
        AppComposition.bootstrapFeatures(mainCoordinator: mainCoordinator)
    }

    var body: some Scene {
        WindowGroup {
            RootView(coordinator: mainCoordinator)
                .onOpenURL { url in
                    guard let destination = DeepLinkRouter.shared.resolve(url: url)
                    else { return }
                    mainCoordinator.handleDeepLinkNavigation(to: destination)
                }
        }
    }
}
```

- [ ] **Step 4: Build the whole app**

Run: `xcodebuild build -scheme ModularNavigationExample -destination 'generic/platform=iOS Simulator' -project ModularNavigationExample.xcodeproj`
Expected: BUILD SUCCEEDED.

- [ ] **Step 5: Manually verify deep links still resolve (replaces the deleted `UsersDeepLinkMapperTests`/covers `ColorsDeepLinkMapper`)**

There is no Xcode unit test target for the `App` target itself (the README already notes the app scheme isn't wired for the test action), so this coverage is manual, run against a booted simulator with the app installed:

```bash
xcrun simctl openurl booted "com.ali.modularnavigationexample://users/details?id=1"
xcrun simctl openurl booted "com.ali.modularnavigationexample://colors/details?id=1"
```
Expected for each: the app switches to the Services tab and pushes the corresponding detail screen (Users' user 1 / Colors' color 1).

```bash
xcrun simctl openurl booted "com.ali.modularnavigationexample://users/list"
xcrun simctl openurl booted "com.ali.modularnavigationexample://nonsense/details?id=1"
```
Expected for each: no navigation happens (both mappers return `nil` for these).

- [ ] **Step 6: Manually verify the in-app cross-feature button**

Launch the app, navigate to Services → Colors, tap the "Users" button. Expected: Users' detail screen for id 1 pushes onto the same stack. On that screen, trigger whatever fires `notifyDetailAction()` (per `UserDetailViewModel`, this is currently not wired to any UI control — confirm in `UserDetailView.swift` whether a control needs adding, or call `viewModel.notifyDetailAction()` from the debugger/a temporary button if none exists) and confirm `didReturnFromSecondaryAction()`'s `print("DEBUG: didReturnFromSecondaryAction")` appears in the Xcode console.

- [ ] **Step 7: Commit**

```bash
git add App
git commit -m "$(cat <<'EOF'
[FEAT] Wire AppComposition and MainCoordinator for app-owned navigation

AppComposition now registers every feature's destination/mapper, and
MainCoordinator handles Colors' one cross-feature action — extending
its existing deep-link-dispatch role. The app builds and runs
end-to-end again with zero Colors<->Users package dependency.
EOF
)"
```

---

### Task 5: Update `README.md`

**Files:**
- Modify: `README.md`

**Interfaces:**
- Consumes: nothing (documentation only).
- Produces: nothing consumed by other tasks — this is the last task.

The README's "Core concepts" table, "2. Cross-feature navigation" section, "3. Deep linking" section, the wiring checklist, and the `FeatureModule`/gotcha notes all describe the old `<FeatureName>API` pattern. This task rewrites them to describe the new model without changing "1. Internal navigation" (still accurate) or "Testing" (still accurate for package-level tests; add one line about the App-level manual verification from Task 4).

- [ ] **Step 1: Rewrite the `Core concepts` table's `NavigationDestination` row**

Find the row:
```
| `NavigationDestination` | `Navigation` (protocol) | A small, feature-owned allowlist of entry points reachable from outside that feature. Declared `public` inside a lightweight `<FeatureName>API` target — a separate SPM product from the feature's main target — so other features can depend on just the destination type, not the feature's views, use cases, or networking. |
```
Replace with:
```
| `NavigationDestination` | `Navigation` (protocol) | A small allowlist of entry points into one feature, reachable from outside it. Declared `public` inside `App/Destinations/`, not inside the feature's own package — the App owns every feature's destination, so no feature ever depends on another feature's package to reach it. |
```

- [ ] **Step 2: Rewrite the "in one line" flow bullets**

Find:
```
- **Cross-feature (in-app):** caller imports the callee's `<FeatureName>API` product → constructs `<FeatureName>Destination` directly → `RouteRegistry.shared.resolve(_:)` → `AnyRoute` → `coordinator.navigate(to:)`.
```
Replace with:
```
- **Cross-feature (in-app):** the feature calls a closure it defined itself and was handed at registration (e.g. `viewModel.crossFeatureActions.onSecondaryAction(...)`) → the App's implementation of that closure resolves the *other* feature's `Destination` via `RouteRegistry.shared.resolve(_:)` → `AnyRoute` → `coordinator.navigate(to:)`. The calling feature never sees the destination type or the registry — only the App does.
```

And update the paragraph immediately after (the one starting "Both flows share the same back half"):
```
Both flows share the same back half (`RouteRegistry` → `AnyRoute` → `coordinator.navigate`), but only the App ever performs it. A feature's only involvement in cross-feature navigation is exposing a closure, in its own vocabulary, that the App fills in — the feature never imports `NavigationDestination`, `RouteRegistry`, or another feature's package.
```

Remove the paragraph that begins "Depending on `<FeatureName>API` reintroduces a compile-time dependency between features..." — it no longer applies, since no feature depends on another feature's package under this model.

- [ ] **Step 3: Replace "2. Cross-feature navigation" entirely**

Replace the whole section (from `## 2. Cross-feature navigation` up to but not including `## 3. Deep linking from the OS`) with:

```markdown
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
```

- [ ] **Step 4: Replace "3. Deep linking from the OS"**

Replace the whole section with:

```markdown
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
```

- [ ] **Step 5: Rewrite the wiring checklist**

Replace the "Checklist: wiring up a new feature" section's body with:

```markdown
- [ ] Create the SPM package under `Packages/Features/<FeatureName>`, depending on `Navigation` + `NetworkService` (via `SharedLibraries`) — nothing else.
- [ ] Define `<FeatureName>Route: Route` with your screens; keep it `public` (the App needs it).
- [ ] Build your views, reading `NavigationCoordinator` via `@EnvironmentObject`.
- [ ] `<FeatureName>Module.register(network:)` should only wire the feature's own DI (repositories/use cases/view models) — never touch `RouteRegistry`/`DeepLinkRouter`.
- [ ] *(Only if other features or deep links must reach in)* Add `public <FeatureName>Destination: NavigationDestination` to `App/Destinations/` — not to the feature's own package.
- [ ] *(Only if the above)* Add a `<FeatureName>DeepLinkMapper: DeepLinkMapper` to `App/Routing/`, and register both it and the destination from `App/AppComposition.swift`.
- [ ] *(For a feature that needs to navigate into another feature)* Give `<FeatureName>Module.register` an extra parameter for the closure it needs (named for the feature's own concern, e.g. `crossFeatureActions:`), thread it down to wherever the trigger lives, and have `AppComposition` supply the real implementation using `MainCoordinator`.
- [ ] Host the feature's root under a `NavigationHost` somewhere (a tab, a nav-linked entry point), with its own `NavigationCoordinator`.

No feature package ever depends on another feature's package, or on `NavigationDestination`/`RouteRegistry`/`DeepLinkRouter` — those are exclusively `App/`'s concern.
```

- [ ] **Step 6: Update the `FeatureModule` gotcha note**

Find:
```
- **`FeatureModule` exists in `Navigation` but isn't currently adopted.** Features register through a plain
  `register(network:)` static method on their own module enum (`FeatureYModule`, `FeatureXModule`), called directly
  from `AppComposition.bootstrapFeatures()` — not through a `[FeatureModule.Type]` array. If you want a uniform
  registration hook across features, conform to it; nothing currently depends on that happening.
```
Replace with:
```
- **`FeatureModule` exists in `Navigation` but isn't currently adopted.** Features expose a plain `register(network:)`
  static method (`UsersModule`, `ColorsModule`) for their own DI only — it no longer touches `RouteRegistry`/
  `DeepLinkRouter` at all. `AppComposition.bootstrapFeatures()` calls each feature's `register`, then separately
  registers that feature's destination/mapper itself. If you want a uniform registration hook across features,
  conform to `FeatureModule`; nothing currently depends on that happening.
```

- [ ] **Step 7: Add a line to "Testing" about the App-level manual verification**

At the end of the `## Testing` section, add:

```markdown
`App/Destinations/`, `App/Routing/`, and `App/AppComposition.swift` have no automated test coverage — there is
no Xcode unit test target for the `App` target itself. Verify deep links manually against a booted simulator:

```
xcrun simctl openurl booted "com.ali.modularnavigationexample://users/details?id=1"
xcrun simctl openurl booted "com.ali.modularnavigationexample://colors/details?id=1"
```
```

- [ ] **Step 8: Read through the whole README once for leftover references**

Run: `grep -n "FeatureYAPI\|<FeatureName>API\|ColorsAPI\|UsersAPI" README.md`
Expected: no output.

- [ ] **Step 9: Commit**

```bash
git add README.md
git commit -m "$(cat <<'EOF'
[DOCS] Rewrite README for app-owned cross-feature navigation

Replaces the <FeatureName>API pattern documentation with the new
model: destinations, deep-link mappers, and registration all live in
App/, and a feature's only cross-feature involvement is an injected
closure named in its own vocabulary.
EOF
)"
```
