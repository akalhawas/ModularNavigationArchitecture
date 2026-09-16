import XCTest
import Combine
@testable import Colors
import Navigation

private final class StubColorsCrossFeatureDelegate: ColorsCrossFeatureDelegate {
    func onPrimaryAction(router: NavigationRouter, id: Int, onReturn: @escaping () -> Void) {}
}

final class ColorsViewModelTests: XCTestCase {

    private var sut: ColorsViewModel!
    private var mockRepo: MockColorRepository!

    override func setUp() {
        super.setUp()
        mockRepo = MockColorRepository()
        sut = ColorsViewModel(
            fetchColorsUseCase: FetchColorsUseCaseImp(repository: mockRepo),
            crossFeatureDelegate: StubColorsCrossFeatureDelegate()
        )
    }

    override func tearDown() {
        sut = nil
        mockRepo = nil
        super.tearDown()
    }

    // MARK: - Fixtures

    private static let mockColor = AppColor(
        id: 1,
        name: "Mock AppColor",
        year: 2026,
        color: "#98B2D1",
        pantoneValue: "15-4020"
    )

    private static func mockColor(id: Int) -> AppColor {
        AppColor(id: id, name: "Mock AppColor \(id)", year: 2026, color: "#98B2D1", pantoneValue: "15-4020")
    }

    private static let mockSupport = SupportInfo(url: "https://reqres.in/#support-heading", text: "Mock data")

    private static func response(_ colors: [AppColor], page: Int = 1) -> ColorListResponse {
        ColorListResponse(page: page, perPage: 6, total: colors.count, totalPages: 1, data: colors, support: mockSupport)
    }

    // MARK: - fetchColors

    func testFetchColorsSuccessUpdatesColorsState() {
        // Given
        mockRepo.colorsResult = .success(Self.response([Self.mockColor]))

        // When
        sut.fetchColors()

        // Then
        XCTAssertEqual(sut.colors, [Self.mockColor])
        XCTAssertNil(sut.errorMessage)
    }

    func testFetchColorsFailureSetsErrorMessage() {
        // Given
        mockRepo.colorsResult = .failure(TestError.network)

        // When
        sut.fetchColors()

        // Then
        XCTAssertEqual(sut.errorMessage, TestError.network.errorDescription)
        XCTAssertTrue(sut.colors.isEmpty)
    }

    func testFetchColorsEmptyResponseClearsColors() {
        // Given
        mockRepo.colorsResult = .success(Self.response([]))

        // When
        sut.fetchColors()

        // Then
        XCTAssertTrue(sut.colors.isEmpty)
        XCTAssertNil(sut.errorMessage)
    }

    func testFetchColorsPassesRequestedPageToRepository() {
        // Given
        mockRepo.colorsResult = .success(Self.response([Self.mockColor], page: 3))

        // When
        sut.fetchColors(page: 3)

        // Then
        XCTAssertEqual(mockRepo.lastPage, 3)
        XCTAssertEqual(mockRepo.fetchColorsCallCount, 1)
    }

    func testFetchColorsRepeatedCallsReplaceState() {
        // Given
        mockRepo.colorsResult = .failure(TestError.generic)

        // When
        sut.fetchColors()
        mockRepo.colorsResult = .success(Self.response([Self.mockColor]))
        sut.fetchColors()

        // Then
        XCTAssertEqual(sut.colors, [Self.mockColor])
        XCTAssertEqual(mockRepo.fetchColorsCallCount, 2)
    }

    // MARK: - didReturnFromAction

    func testDidReturnFromActionDropsTheLastColor() {
        // Given
        let colors = (1...3).map(Self.mockColor(id:))
        mockRepo.colorsResult = .success(Self.response(colors))
        sut.fetchColors()

        // When
        sut.didReturnFromAction()

        // Then
        XCTAssertEqual(sut.colors, Array(colors.prefix(2)))
    }

    func testDidReturnFromActionOnEmptyColorsIsANoOp() {
        // When
        sut.didReturnFromAction()

        // Then
        XCTAssertTrue(sut.colors.isEmpty)
    }

    // MARK: - crossFeatureDelegate

    func testExposesTheInjectedCrossFeatureDelegate() {
        // Given
        let delegate = StubColorsCrossFeatureDelegate()
        let sut = ColorsViewModel(
            fetchColorsUseCase: FetchColorsUseCaseImp(repository: mockRepo),
            crossFeatureDelegate: delegate
        )

        // Then
        XCTAssertTrue(sut.crossFeatureDelegate === delegate)
    }

    @MainActor
    func testCrossFeatureDelegateReceivesRequestedIdAndReturnCallback() {
        // Given
        final class CapturingDelegate: ColorsCrossFeatureDelegate {
            var capturedId: Int?
            var capturedOnReturn: (() -> Void)?
            func onPrimaryAction(router: NavigationRouter, id: Int, onReturn: @escaping () -> Void) {
                capturedId = id
                capturedOnReturn = onReturn
            }
        }
        let delegate = CapturingDelegate()
        let sut = ColorsViewModel(
            fetchColorsUseCase: FetchColorsUseCaseImp(repository: mockRepo),
            crossFeatureDelegate: delegate
        )
        var didReturn = false

        // When
        sut.crossFeatureDelegate?.onPrimaryAction(router: NavigationRouter(), id: 9) { didReturn = true }
        delegate.capturedOnReturn?()

        // Then
        XCTAssertEqual(delegate.capturedId, 9)
        XCTAssertTrue(didReturn)
    }
}
