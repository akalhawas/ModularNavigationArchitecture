//
//  MockUserRepository.swift
//  UsersTests
//

import Combine
@testable import Users

final class MockUserRepository: UserRepository {

    var usersResult: Result<UserListResponse, Error> = .failure(TestError.generic)
    var userResult: Result<UserDetailResponse, Error> = .failure(TestError.generic)
    var permissionResult: Result<Bool, Error> = .failure(TestError.generic)
    private(set) var lastPage: Int?
    private(set) var lastId: Int?
    private(set) var lastPermissionUserId: Int?

    func fetchUsers(page: Int) -> AnyPublisher<UserListResponse, Error> {
        lastPage = page
        return usersResult.publisher.eraseToAnyPublisher()
    }

    func fetchUser(id: Int) -> AnyPublisher<UserDetailResponse, Error> {
        lastId = id
        return userResult.publisher.eraseToAnyPublisher()
    }

    func checkPermission(userId: Int) -> AnyPublisher<Bool, Error> {
        lastPermissionUserId = userId
        return permissionResult.publisher.eraseToAnyPublisher()
    }
}
