//
//  AppComposition.swift
//  ModularizedByFeature
//
//  Created by ali alhawas on 24/07/2026.
//

import SwiftUI

@MainActor
enum AppComposition {
    // MARK: Register new feature
    static func bootstrapFeatures() {
        UsersModule.register(network: AppDependencies.shared.networkService)
        ColorsModule.register(network: AppDependencies.shared.networkService)
    }
}
