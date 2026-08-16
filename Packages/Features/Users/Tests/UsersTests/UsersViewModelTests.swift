//
//  UsersViewModelTests.swift
//  UsersTests
//

import XCTest
@testable import Users

final class UsersViewModelTests: XCTestCase {

    private static let mockUser = User(
        id: 1,
        email: "mock.user@example.com",
        firstName: "Mock",
        lastName: "User",
        avatar: ""
    )

    private static let mockSupport = SupportInfo(url: "https://reqres.in/#support-heading", text: "Mock data")

    private func makeSUT(useCase: MockFetchUsersUseCase = MockFetchUsersUseCase()) -> UsersViewModel {
        UsersViewModel(fetchUsersUseCase: useCase)
    }

    func testFetchUsersSuccessUpdatesUsersState() {
        // Arrange
        let useCase = MockFetchUsersUseCase()
        let response = UserListResponse(
            page: 1,
            perPage: 6,
            total: 1,
            totalPages: 1,
            data: [Self.mockUser],
            support: Self.mockSupport
        )
        useCase.result = .success(response)
        let sut = makeSUT(useCase: useCase)

        // Act
        sut.fetchUsers()

        // Assert
        XCTAssertEqual(sut.users, [Self.mockUser])
        XCTAssertNil(sut.errorMessage)
    }

    func testFetchUsersFailureSetsErrorMessage() {
        // Arrange
        let useCase = MockFetchUsersUseCase()
        useCase.result = .failure(TestError.network)
        let sut = makeSUT(useCase: useCase)

        // Act
        sut.fetchUsers()

        // Assert
        XCTAssertEqual(sut.errorMessage, TestError.network.errorDescription)
        XCTAssertTrue(sut.users.isEmpty)
    }

    func testFetchUsersEmptyResponseClearsUsers() {
        // Arrange
        let useCase = MockFetchUsersUseCase()
        let response = UserListResponse(page: 1, perPage: 6, total: 0, totalPages: 0, data: [], support: Self.mockSupport)
        useCase.result = .success(response)
        let sut = makeSUT(useCase: useCase)

        // Act
        sut.fetchUsers()

        // Assert
        XCTAssertTrue(sut.users.isEmpty)
        XCTAssertNil(sut.errorMessage)
    }

    func testFetchUsersPassesRequestedPageToUseCase() {
        // Arrange
        let useCase = MockFetchUsersUseCase()
        useCase.result = .success(
            UserListResponse(page: 3, perPage: 6, total: 1, totalPages: 1, data: [Self.mockUser], support: Self.mockSupport)
        )
        let sut = makeSUT(useCase: useCase)

        // Act
        sut.fetchUsers(page: 3)

        // Assert
        XCTAssertEqual(useCase.lastPage, 3)
        XCTAssertEqual(useCase.executeCallCount, 1)
    }

    func testFetchUsersRepeatedCallsReplaceState() {
        // Arrange
        let useCase = MockFetchUsersUseCase()
        useCase.result = .failure(TestError.generic)
        let sut = makeSUT(useCase: useCase)

        // Act
        sut.fetchUsers()
        useCase.result = .success(
            UserListResponse(page: 1, perPage: 6, total: 1, totalPages: 1, data: [Self.mockUser], support: Self.mockSupport)
        )
        sut.fetchUsers()

        // Assert
        XCTAssertEqual(sut.users, [Self.mockUser])
        XCTAssertEqual(useCase.executeCallCount, 2)
    }
}
