//
//  FetchColorDetailUseCaseTests.swift
//  ColorsTests
//

import XCTest
@testable import Colors

final class FetchColorDetailUseCaseTests: XCTestCase {

    private static let mockColor = AppColor(
        id: 42,
        name: "Mock AppColor",
        year: 2026,
        color: "#98B2D1",
        pantoneValue: "15-4020"
    )

    private static let mockSupport = SupportInfo(url: "https://reqres.in/#support-heading", text: "Mock data")

    func testExecuteSuccessReturnsRepositoryResponse() {
        // Arrange
        let repository = MockColorRepository()
        repository.colorResult = .success(ColorDetailResponse(data: Self.mockColor, support: Self.mockSupport))
        let sut = FetchColorDetailUseCaseImp(repository: repository)

        // Act
        var received: ColorDetailResponse?
        _ = sut.execute(id: 42).sink(receiveCompletion: { _ in }, receiveValue: { received = $0 })

        // Assert
        XCTAssertEqual(received?.data, Self.mockColor)
    }

    func testExecutePassesIdToRepository() {
        // Arrange
        let repository = MockColorRepository()
        repository.colorResult = .success(ColorDetailResponse(data: Self.mockColor, support: Self.mockSupport))
        let sut = FetchColorDetailUseCaseImp(repository: repository)

        // Act
        _ = sut.execute(id: 99).sink(receiveCompletion: { _ in }, receiveValue: { _ in })

        // Assert
        XCTAssertEqual(repository.lastId, 99)
    }

    func testExecuteFailurePropagatesRepositoryError() {
        // Arrange
        let repository = MockColorRepository()
        repository.colorResult = .failure(TestError.network)
        let sut = FetchColorDetailUseCaseImp(repository: repository)

        // Act
        var receivedError: TestError?
        _ = sut.execute(id: 1).sink(receiveCompletion: { completion in
            if case .failure(let error) = completion {
                receivedError = error as? TestError
            }
        }, receiveValue: { _ in })

        // Assert
        XCTAssertEqual(receivedError, TestError.network)
    }
}
