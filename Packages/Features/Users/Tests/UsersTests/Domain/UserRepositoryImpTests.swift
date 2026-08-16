//
//  UserRepositoryImpTests.swift
//  UsersTests
//

import XCTest
import NetworkService
@testable import Users

final class UserRepositoryImpTests: XCTestCase {

    private static let mockUser = User(
        id: 7,
        email: "mock.user@example.com",
        firstName: "Mock",
        lastName: "User",
        avatar: ""
    )

    private static let mockSupport = SupportInfo(url: "https://reqres.in/#support-heading", text: "Mock data")

    func testFetchUsersSuccessReturnsDecodedResponse() {
        // Arrange
        let network = MockNetworkService()
        let response = UserListResponse(page: 1, perPage: 6, total: 1, totalPages: 1, data: [Self.mockUser], support: Self.mockSupport)
        network.result = .success(response)
        let sut = UserRepositoryImp(networkService: network)

        // Act
        var received: UserListResponse?
        _ = sut.fetchUsers(page: 1).sink(receiveCompletion: { _ in }, receiveValue: { received = $0 })

        // Assert
        XCTAssertEqual(received?.data, [Self.mockUser])
    }

    func testFetchUsersRequestsListEndpointWithPage() {
        // Arrange
        let network = MockNetworkService()
        network.result = .success(
            UserListResponse(page: 5, perPage: 6, total: 1, totalPages: 1, data: [Self.mockUser], support: Self.mockSupport)
        )
        let sut = UserRepositoryImp(networkService: network)

        // Act
        _ = sut.fetchUsers(page: 5).sink(receiveCompletion: { _ in }, receiveValue: { _ in })

        // Assert
        guard case .list(let page) = network.requestedEndpoints.first as? UserEndpoint else {
            return XCTFail("Expected UserEndpoint.list")
        }
        XCTAssertEqual(page, 5)
    }

    func testFetchUsersFailurePropagatesError() {
        // Arrange
        let network = MockNetworkService()
        network.result = .failure(TestError.network)
        let sut = UserRepositoryImp(networkService: network)

        // Act
        var receivedError: TestError?
        _ = sut.fetchUsers(page: 1).sink(receiveCompletion: { completion in
            if case .failure(let error) = completion {
                receivedError = error as? TestError
            }
        }, receiveValue: { _ in })

        // Assert
        XCTAssertEqual(receivedError, TestError.network)
    }

    func testFetchUserSuccessReturnsDecodedResponse() {
        // Arrange
        let network = MockNetworkService()
        network.result = .success(UserDetailResponse(data: Self.mockUser, support: Self.mockSupport))
        let sut = UserRepositoryImp(networkService: network)

        // Act
        var received: UserDetailResponse?
        _ = sut.fetchUser(id: 7).sink(receiveCompletion: { _ in }, receiveValue: { received = $0 })

        // Assert
        XCTAssertEqual(received?.data, Self.mockUser)
    }

    func testFetchUserRequestsDetailEndpointWithId() {
        // Arrange
        let network = MockNetworkService()
        network.result = .success(UserDetailResponse(data: Self.mockUser, support: Self.mockSupport))
        let sut = UserRepositoryImp(networkService: network)

        // Act
        _ = sut.fetchUser(id: 9).sink(receiveCompletion: { _ in }, receiveValue: { _ in })

        // Assert
        guard case .detail(let id) = network.requestedEndpoints.first as? UserEndpoint else {
            return XCTFail("Expected UserEndpoint.detail")
        }
        XCTAssertEqual(id, 9)
    }

    func testFetchUserFailurePropagatesError() {
        // Arrange
        let network = MockNetworkService()
        network.result = .failure(TestError.network)
        let sut = UserRepositoryImp(networkService: network)

        // Act
        var receivedError: TestError?
        _ = sut.fetchUser(id: 1).sink(receiveCompletion: { completion in
            if case .failure(let error) = completion {
                receivedError = error as? TestError
            }
        }, receiveValue: { _ in })

        // Assert
        XCTAssertEqual(receivedError, TestError.network)
    }
}
