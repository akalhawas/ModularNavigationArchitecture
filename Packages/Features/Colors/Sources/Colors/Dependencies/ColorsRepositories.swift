//
//  ColorsRepositories.swift
//  Colors
//
//  Created by ali alhawas on 24/07/2026.
//

import NetworkService

protocol ColorsRepositories {
    var colorsRepository: ColorRepository { get }
}

final class Repositories: ColorsRepositories {

    private let networkService: NetworkService

    init(networkService: NetworkService) {
        self.networkService = networkService
    }

    lazy var colorsRepository: ColorRepository = ColorRepositoryImp(networkService: networkService)
}

final class MockRepositories: ColorsRepositories {
    lazy var colorsRepository: ColorRepository = ColorRepositoryMock()
}
