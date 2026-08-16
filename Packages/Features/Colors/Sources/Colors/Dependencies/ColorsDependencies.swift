//
//  ColorsDependencies.swift
//  Colors
//
//  Created by ali alhawas on 24/07/2026.
//

import NetworkService

struct ColorsDependencies {

    let networkService: NetworkService
    let repositories: ColorsRepositories
    let useCases: ColorsUseCases
    let viewModels: ColorsViewModels

    init(network: NetworkService) {
        self.networkService = network
        self.repositories = ColorsDependencies.createRepositories(networkService: network)
        self.useCases = ColorsUseCases(repositories: repositories)
        self.viewModels = ColorsViewModels(useCases: useCases)
    }

    private static func createRepositories(networkService: NetworkService) -> ColorsRepositories {
        #if LOCALDEBUG
        return MockRepositories()
        #else
        return Repositories(networkService: networkService)
        #endif
    }
}
