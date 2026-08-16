//
//  FetchUserDetailUseCase.swift
//  ModularizedByFeature
//
//  Created by ali alhawas on 23/07/2026.
//

import Combine

protocol FetchUserDetailUseCase {
    func execute(id: Int) -> AnyPublisher<UserDetailResponse, Error>
}

final class FetchUserDetailUseCaseImp: FetchUserDetailUseCase {

    private let repository: UserRepository

    init(repository: UserRepository) {
        self.repository = repository
    }

    func execute(id: Int) -> AnyPublisher<UserDetailResponse, Error> {
        repository.fetchUser(id: id)
    }
}
