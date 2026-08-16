//
//  FetchUserDetailUseCaseTests.swift
//  UsersTests
//

import XCTest
@testable import Users

final class FetchUserDetailUseCaseTests: XCTestCase {

    private static let mockUser = User(
        id: 42,
        email: "mock.user@example.com",
        firstName: "Mock",
        lastName: "User",
        avatar: ""
    )

    private static let mockSupport = SupportInfo(url: "https://reqres.in/#support-heading", text: "Mock data")

    func testExecuteSuccessReturnsRepositoryResponse() {
        // Arrange
        let repository = MockUserRepository()
        repository.userResult = .success(UserDetailResponse(data: Self.mockUser, support: Self.mockSupport))
        let sut = FetchUserDetailUseCaseImp(repository: repository)

        // Act
        var received: UserDetailResponse?
        _ = sut.execute(id: 42).sink(receiveCompletion: { _ in }, receiveValue: { received = $0 })

        // Assert
        XCTAssertEqual(received?.data, Self.mockUser)
    }

    func testExecutePassesIdToRepository() {
        // Arrange
        let repository = MockUserRepository()
        repository.userResult = .success(UserDetailResponse(data: Self.mockUser, support: Self.mockSupport))
        let sut = FetchUserDetailUseCaseImp(repository: repository)

        // Act
        _ = sut.execute(id: 99).sink(receiveCompletion: { _ in }, receiveValue: { _ in })

        // Assert
        XCTAssertEqual(repository.lastId, 99)
    }

    func testExecuteFailurePropagatesRepositoryError() {
        // Arrange
        let repository = MockUserRepository()
        repository.userResult = .failure(TestError.network)
        let sut = FetchUserDetailUseCaseImp(repository: repository)

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
