//
//  UserDetailViewModelTests.swift
//  UsersTests
//

import XCTest
@testable import Users

final class UserDetailViewModelTests: XCTestCase {

    private static let mockUser = User(
        id: 42,
        email: "mock.user@example.com",
        firstName: "Mock",
        lastName: "User",
        avatar: ""
    )

    private static let mockSupport = SupportInfo(url: "https://reqres.in/#support-heading", text: "Mock data")

    private func makeSUT(
        userId: Int = 42,
        useCase: MockFetchUserDetailUseCase = MockFetchUserDetailUseCase()
    ) -> UserDetailViewModel {
        UserDetailViewModel(userId: userId, fetchUserDetailUseCase: useCase)
    }

    func testFetchUserSuccessUpdatesUserState() {
        // Arrange
        let useCase = MockFetchUserDetailUseCase()
        useCase.result = .success(UserDetailResponse(data: Self.mockUser, support: Self.mockSupport))
        let sut = makeSUT(useCase: useCase)

        // Act
        sut.fetchUser()

        // Assert
        XCTAssertEqual(sut.user, Self.mockUser)
        XCTAssertNil(sut.errorMessage)
    }

    func testFetchUserFailureSetsErrorMessage() {
        // Arrange
        let useCase = MockFetchUserDetailUseCase()
        useCase.result = .failure(TestError.network)
        let sut = makeSUT(useCase: useCase)

        // Act
        sut.fetchUser()

        // Assert
        XCTAssertEqual(sut.errorMessage, TestError.network.errorDescription)
        XCTAssertNil(sut.user)
    }

    func testFetchUserPassesInjectedIdToUseCase() {
        // Arrange
        let useCase = MockFetchUserDetailUseCase()
        useCase.result = .success(UserDetailResponse(data: Self.mockUser, support: Self.mockSupport))
        let sut = makeSUT(userId: 99, useCase: useCase)

        // Act
        sut.fetchUser()

        // Assert
        XCTAssertEqual(useCase.lastId, 99)
        XCTAssertEqual(useCase.executeCallCount, 1)
    }

    func testFetchUserRepeatedCallsReplaceState() {
        // Arrange
        let useCase = MockFetchUserDetailUseCase()
        useCase.result = .failure(TestError.generic)
        let sut = makeSUT(useCase: useCase)

        // Act
        sut.fetchUser()
        useCase.result = .success(UserDetailResponse(data: Self.mockUser, support: Self.mockSupport))
        sut.fetchUser()

        // Assert
        XCTAssertEqual(sut.user, Self.mockUser)
        XCTAssertEqual(useCase.executeCallCount, 2)
    }
}
