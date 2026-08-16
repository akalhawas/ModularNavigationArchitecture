//
//  LatestColorsViewModelTests.swift
//  ColorsTests
//

import XCTest
import Combine
@testable import Colors

final class LatestColorsViewModelTests: XCTestCase {

    private var cancellables = Set<AnyCancellable>()

    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }

    private func makeSUT(
        useCase: MockFetchColorsUseCase = MockFetchColorsUseCase(),
        limit: Int = 10
    ) -> LatestColorsViewModel {
        LatestColorsViewModel(fetchColorsUseCase: useCase, limit: limit)
    }

    private static let mockSupport = SupportInfo(url: "https://reqres.in/#support-heading", text: "Mock data")

    private static func mockColor(id: Int) -> AppColor {
        AppColor(id: id, name: "Mock AppColor \(id)", year: 2026, color: "#98B2D1", pantoneValue: "15-4020")
    }

    func testFetchLatestColorsSuccessTrimsToLimit() {
        // Arrange
        let useCase = MockFetchColorsUseCase()
        let colors = (1...5).map(Self.mockColor)
        useCase.result = .success(
            ColorListResponse(page: 1, perPage: 6, total: 5, totalPages: 1, data: colors, support: Self.mockSupport)
        )
        let sut = makeSUT(useCase: useCase, limit: 3)
        let didPublish = expectation(description: "colors published")
        sut.$colors.dropFirst().sink { _ in didPublish.fulfill() }.store(in: &cancellables)

        // Act
        sut.fetchLatestColors()
        wait(for: [didPublish], timeout: 1)

        // Assert
        XCTAssertEqual(sut.colors, Array(colors.prefix(3)))
        XCTAssertNil(sut.errorMessage)
    }

    func testFetchLatestColorsSuccessWithFewerItemsThanLimitReturnsAll() {
        // Arrange
        let useCase = MockFetchColorsUseCase()
        let colors = [Self.mockColor(id: 1), Self.mockColor(id: 2)]
        useCase.result = .success(
            ColorListResponse(page: 1, perPage: 6, total: 2, totalPages: 1, data: colors, support: Self.mockSupport)
        )
        let sut = makeSUT(useCase: useCase, limit: 10)
        let didPublish = expectation(description: "colors published")
        sut.$colors.dropFirst().sink { _ in didPublish.fulfill() }.store(in: &cancellables)

        // Act
        sut.fetchLatestColors()
        wait(for: [didPublish], timeout: 1)

        // Assert
        XCTAssertEqual(sut.colors, colors)
    }

    func testFetchLatestColorsFailureSetsErrorMessage() {
        // Arrange
        let useCase = MockFetchColorsUseCase()
        useCase.result = .failure(TestError.network)
        let sut = makeSUT(useCase: useCase)
        let didPublish = expectation(description: "errorMessage published")
        sut.$errorMessage.compactMap { $0 }.sink { _ in didPublish.fulfill() }.store(in: &cancellables)

        // Act
        sut.fetchLatestColors()
        wait(for: [didPublish], timeout: 1)

        // Assert
        XCTAssertEqual(sut.errorMessage, TestError.network.errorDescription)
        XCTAssertTrue(sut.colors.isEmpty)
    }

    func testFetchLatestColorsRequestsFirstPage() {
        // Arrange
        let useCase = MockFetchColorsUseCase()
        useCase.result = .success(
            ColorListResponse(page: 1, perPage: 6, total: 1, totalPages: 1, data: [Self.mockColor(id: 1)], support: Self.mockSupport)
        )
        let sut = makeSUT(useCase: useCase)

        // Act
        sut.fetchLatestColors()

        // Assert
        XCTAssertEqual(useCase.lastPage, 1)
        XCTAssertEqual(useCase.executeCallCount, 1)
    }
}
