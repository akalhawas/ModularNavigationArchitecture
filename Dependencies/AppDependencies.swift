//
//  AppDependencies.swift
//  ModularizedByFeature
//
//  Created by ali alhawas on 23/07/2026.
//

import NetworkService

final class AppDependencies {

    static let shared = AppDependencies()

    let networkService: NetworkService

    private init() {
        self.networkService = AppDependencies.createNetworkService()
    }

    private static func createNetworkService() -> NetworkService {
        return NetworkServiceImp()
    }
}
