//
//  UserRepositoryImp.swift
//  Users
//
//  Created by ali alhawas on 23/07/2026.
//

import Combine
import NetworkService

final class UserRepositoryImp: UserRepository {

    private let networkService: NetworkService

    init(networkService: NetworkService) {
        self.networkService = networkService
    }

    func fetchUsers(page: Int) -> AnyPublisher<UserListResponse, Error> {
        networkService.request(UserEndpoint.list(page: page))
    }

    func fetchUser(id: Int) -> AnyPublisher<UserDetailResponse, Error> {
        networkService.request(UserEndpoint.detail(id: id))
    }

    func checkPermission(userId: Int) -> AnyPublisher<Bool, Error> {
        networkService.request(UserEndpoint.permission(id: userId))
            .map { (response: PermissionResponse) in response.allowed }
            .eraseToAnyPublisher()
    }
}
