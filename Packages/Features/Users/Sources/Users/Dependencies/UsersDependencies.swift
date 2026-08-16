//
//  UsersDependencies.swift
//  Users
//
//  Created by ali alhawas on 23/07/2026.
//

import NetworkService

struct UsersDependencies {
    
    let networkService: NetworkService
    let repositories: UsersRepositories
    let useCases: UsersUseCases
    let viewModels: UsersViewModels

    init(network: NetworkService) {
        self.networkService = network
        self.repositories = UsersDependencies.createRepositories(networkService: network)
        self.useCases = UsersUseCases(repositories: repositories)
        self.viewModels = UsersViewModels(useCases: useCases)
    }

    private static func createRepositories(networkService: NetworkService) -> UsersRepositories {
        #if LOCALDEBUG
        return MockRepositories()
        #else
        return Repositories(networkService: networkService)
        #endif
    }
}
