//
//  ColorDetailViewModelTests.swift
//  ColorsTests
//

import XCTest
@testable import Colors

final class ColorDetailViewModelTests: XCTestCase {

    private static let mockColor = AppColor(
        id: 42,
        name: "Mock AppColor",
        year: 2026,
        color: "#98B2D1",
        pantoneValue: "15-4020"
    )

    private static let mockSupport = SupportInfo(url: "https://reqres.in/#support-heading", text: "Mock data")

    private func makeSUT(
        colorId: Int = 42,
        useCase: MockFetchColorDetailUseCase = MockFetchColorDetailUseCase()
    ) -> ColorDetailViewModel {
        ColorDetailViewModel(colorId: colorId, fetchColorDetailUseCase: useCase)
    }

    func testFetchColorSuccessUpdatesColorState() {
        // Arrange
        let useCase = MockFetchColorDetailUseCase()
        useCase.result = .success(ColorDetailResponse(data: Self.mockColor, support: Self.mockSupport))
        let sut = makeSUT(useCase: useCase)

        // Act
        sut.fetchColor()

        // Assert
        XCTAssertEqual(sut.color, Self.mockColor)
        XCTAssertNil(sut.errorMessage)
    }

    func testFetchColorFailureSetsErrorMessage() {
        // Arrange
        let useCase = MockFetchColorDetailUseCase()
        useCase.result = .failure(TestError.network)
        let sut = makeSUT(useCase: useCase)

        // Act
        sut.fetchColor()

        // Assert
        XCTAssertEqual(sut.errorMessage, TestError.network.errorDescription)
        XCTAssertNil(sut.color)
    }

    func testFetchColorPassesInjectedIdToUseCase() {
        // Arrange
        let useCase = MockFetchColorDetailUseCase()
        useCase.result = .success(ColorDetailResponse(data: Self.mockColor, support: Self.mockSupport))
        let sut = makeSUT(colorId: 99, useCase: useCase)

        // Act
        sut.fetchColor()

        // Assert
        XCTAssertEqual(useCase.lastId, 99)
        XCTAssertEqual(useCase.executeCallCount, 1)
    }

    func testFetchColorRepeatedCallsReplaceState() {
        // Arrange
        let useCase = MockFetchColorDetailUseCase()
        useCase.result = .failure(TestError.generic)
        let sut = makeSUT(useCase: useCase)

        // Act
        sut.fetchColor()
        useCase.result = .success(ColorDetailResponse(data: Self.mockColor, support: Self.mockSupport))
        sut.fetchColor()

        // Assert
        XCTAssertEqual(sut.color, Self.mockColor)
        XCTAssertEqual(useCase.executeCallCount, 2)
    }
}
