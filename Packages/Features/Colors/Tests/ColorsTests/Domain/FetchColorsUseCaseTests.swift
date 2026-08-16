//
//  FetchColorsUseCaseTests.swift
//  ColorsTests
//

import XCTest
@testable import Colors

final class FetchColorsUseCaseTests: XCTestCase {

    private static let mockColor = AppColor(
        id: 1,
        name: "Mock AppColor",
        year: 2026,
        color: "#98B2D1",
        pantoneValue: "15-4020"
    )

    private static let mockSupport = SupportInfo(url: "https://reqres.in/#support-heading", text: "Mock data")

    func testExecuteSuccessReturnsRepositoryResponse() {
        // Arrange
        let repository = MockColorRepository()
        let response = ColorListResponse(page: 1, perPage: 6, total: 1, totalPages: 1, data: [Self.mockColor], support: Self.mockSupport)
        repository.colorsResult = .success(response)
        let sut = FetchColorsUseCaseImp(repository: repository)

        // Act
        var received: ColorListResponse?
        _ = sut.execute(page: 1).sink(receiveCompletion: { _ in }, receiveValue: { received = $0 })

        // Assert
        XCTAssertEqual(received?.data, [Self.mockColor])
    }

    func testExecutePassesPageToRepository() {
        // Arrange
        let repository = MockColorRepository()
        repository.colorsResult = .success(
            ColorListResponse(page: 2, perPage: 6, total: 1, totalPages: 1, data: [Self.mockColor], support: Self.mockSupport)
        )
        let sut = FetchColorsUseCaseImp(repository: repository)

        // Act
        _ = sut.execute(page: 2).sink(receiveCompletion: { _ in }, receiveValue: { _ in })

        // Assert
        XCTAssertEqual(repository.lastPage, 2)
    }

    func testExecuteFailurePropagatesRepositoryError() {
        // Arrange
        let repository = MockColorRepository()
        repository.colorsResult = .failure(TestError.network)
        let sut = FetchColorsUseCaseImp(repository: repository)

        // Act
        var receivedError: TestError?
        _ = sut.execute(page: 1).sink(receiveCompletion: { completion in
            if case .failure(let error) = completion {
                receivedError = error as? TestError
            }
        }, receiveValue: { _ in })

        // Assert
        XCTAssertEqual(receivedError, TestError.network)
    }
}
