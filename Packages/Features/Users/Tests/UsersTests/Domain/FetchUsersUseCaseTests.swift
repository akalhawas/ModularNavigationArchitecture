//
//  FetchUsersUseCaseTests.swift
//  UsersTests
//

import XCTest
@testable import Users

final class FetchUsersUseCaseTests: XCTestCase {

    private static let mockUser = User(
        id: 1,
        email: "mock.user@example.com",
        firstName: "Mock",
        lastName: "User",
        avatar: ""
    )

    private static let mockSupport = SupportInfo(url: "https://reqres.in/#support-heading", text: "Mock data")

    func testExecuteSuccessReturnsRepositoryResponse() {
        // Arrange
        let repository = MockUserRepository()
        let response = UserListResponse(page: 1, perPage: 6, total: 1, totalPages: 1, data: [Self.mockUser], support: Self.mockSupport)
        repository.usersResult = .success(response)
        let sut = FetchUsersUseCaseImp(repository: repository)

        // Act
        var received: UserListResponse?
        _ = sut.execute(page: 1).sink(receiveCompletion: { _ in }, receiveValue: { received = $0 })

        // Assert
        XCTAssertEqual(received?.data, [Self.mockUser])
    }

    func testExecutePassesPageToRepository() {
        // Arrange
        let repository = MockUserRepository()
        repository.usersResult = .success(
            UserListResponse(page: 2, perPage: 6, total: 1, totalPages: 1, data: [Self.mockUser], support: Self.mockSupport)
        )
        let sut = FetchUsersUseCaseImp(repository: repository)

        // Act
        _ = sut.execute(page: 2).sink(receiveCompletion: { _ in }, receiveValue: { _ in })

        // Assert
        XCTAssertEqual(repository.lastPage, 2)
    }

    func testExecuteFailurePropagatesRepositoryError() {
        // Arrange
        let repository = MockUserRepository()
        repository.usersResult = .failure(TestError.network)
        let sut = FetchUsersUseCaseImp(repository: repository)

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
