//
//  UserRepository.swift
//  Users
//
//  Created by ali alhawas on 23/07/2026.
//

import Combine

protocol UserRepository {
    func fetchUsers(page: Int) -> AnyPublisher<UserListResponse, Error>
    func fetchUser(id: Int) -> AnyPublisher<UserDetailResponse, Error>
}
