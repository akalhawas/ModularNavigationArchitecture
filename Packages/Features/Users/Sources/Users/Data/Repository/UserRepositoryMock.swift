//
//  UserRepositoryMock.swift
//  Users
//
//  Created by ali alhawas on 23/07/2026.
//

import Combine

final class UserRepositoryMock: UserRepository {

    func fetchUsers(page: Int) -> AnyPublisher<UserListResponse, Error> {
        let response = UserListResponse(
            page: page,
            perPage: 6,
            total: 1,
            totalPages: 1,
            data: [Self.mockUser],
            support: Self.mockSupport
        )
        return Just(response).setFailureType(to: Error.self).eraseToAnyPublisher()
    }

    func fetchUser(id: Int) -> AnyPublisher<UserDetailResponse, Error> {
        let response = UserDetailResponse(data: Self.mockUser, support: Self.mockSupport)
        return Just(response).setFailureType(to: Error.self).eraseToAnyPublisher()
    }

    private static let mockUser = User(
        id: 1,
        email: "mock.user@example.com",
        firstName: "Mock",
        lastName: "User",
        avatar: ""
    )

    private static let mockSupport = SupportInfo(url: "https://reqres.in/#support-heading", text: "Mock data")
}
