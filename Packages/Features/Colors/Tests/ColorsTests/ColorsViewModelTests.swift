import XCTest
@testable import Colors
import Navigation

private final class StubColorsCrossFeatureDelegate: ColorsCrossFeatureDelegate {
    func onTertiaryAction(coordinator: NavigationCoordinator, id: Int, onReturn: @escaping () -> Void) {}
}

final class ColorsViewModelTests: XCTestCase {

    private func makeSUT(
        useCase: MockFetchColorsUseCase = MockFetchColorsUseCase(),
        crossFeatureActions: ColorsCrossFeatureActions = ColorsCrossFeatureActions(onSecondaryAction: { _, _, _ in }),
        crossFeatureDelegate: ColorsCrossFeatureDelegate? = StubColorsCrossFeatureDelegate()
    ) -> ColorsViewModel {
        ColorsViewModel(fetchColorsUseCase: useCase, crossFeatureActions: crossFeatureActions, crossFeatureDelegate: crossFeatureDelegate)
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

    @MainActor
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

    @MainActor
    func testExposesTheInjectedCrossFeatureDelegate() {
        // Arrange
        final class CapturingDelegate: ColorsCrossFeatureDelegate {
            var capturedId: Int?
            func onTertiaryAction(coordinator: NavigationCoordinator, id: Int, onReturn: @escaping () -> Void) {
                capturedId = id
            }
        }
        let delegate = CapturingDelegate()
        let sut = makeSUT(crossFeatureDelegate: delegate)

        // Act
        sut.crossFeatureDelegate?.onTertiaryAction(coordinator: NavigationCoordinator(), id: 9, onReturn: {})

        // Assert
        XCTAssertEqual(delegate.capturedId, 9)
    }
}
