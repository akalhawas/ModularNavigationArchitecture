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
    static func bootstrapFeatures(mainCoordinator: MainCoordinator) {
        UsersModule.register(network: AppDependencies.shared.networkService)
        registerUsersRouting()

        ColorsModule.register(
            network: AppDependencies.shared.networkService,
            crossFeatureActions: ColorsCrossFeatureActions(
                onSecondaryAction: mainCoordinator.handleColorsSecondaryAction
            )
        )
        registerColorsRouting()
    }

    private static func registerColorsRouting() {
        RouteRegistry.shared.register(ColorsDestination.self) { destination in
            switch destination {
            case .details(let id):
                return AnyRoute(ColorsRoute.colorDetail(id: id))
            }
        }
        DeepLinkRouter.shared.register(ColorsDeepLinkMapper())
    }

    private static func registerUsersRouting() {
        RouteRegistry.shared.register(UsersDestination.self) { destination in
            switch destination {
            case .details(let id, let onDetailAction):
                return AnyRoute(UsersRoute.userDetail(id: id, onDetailAction: onDetailAction))
            }
        }
        DeepLinkRouter.shared.register(UsersDeepLinkMapper())
    }
}
