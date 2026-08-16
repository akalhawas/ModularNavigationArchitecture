//
//  NCGRRepositories.swift
//  Users
//
//  Created by ali alhawas on 23/07/2026.
//

import NetworkService

protocol UsersRepositories {
    var usersRepository: UserRepository { get }
}

final class Repositories: UsersRepositories {

    private let networkService: NetworkService

    init(networkService: NetworkService) {
        self.networkService = networkService
    }
    
    lazy var usersRepository: UserRepository = UserRepositoryImp(networkService: networkService)
}

final class MockRepositories: UsersRepositories {
    lazy var usersRepository: UserRepository = UserRepositoryMock()
}
