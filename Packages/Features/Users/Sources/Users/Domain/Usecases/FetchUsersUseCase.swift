//
//  FetchUsersUseCase.swift
//  ModularizedByFeature
//
//  Created by ali alhawas on 23/07/2026.
//

import Combine

protocol FetchUsersUseCase {
    func execute(page: Int) -> AnyPublisher<UserListResponse, Error>
}

final class FetchUsersUseCaseImp: FetchUsersUseCase {

    private let repository: UserRepository

    init(repository: UserRepository) {
        self.repository = repository
    }

    func execute(page: Int) -> AnyPublisher<UserListResponse, Error> {
        repository.fetchUsers(page: page)
    }
}
