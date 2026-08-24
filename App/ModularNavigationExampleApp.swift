//
//  ModularNavigationExampleApp.swift
//  ModularNavigationExample
//
//  Created by ali alhawas on 10/07/2026.
//

import SwiftUI
import Combine
@_exported import Users
@_exported import Colors
@_exported import Navigation

@main
struct ModularizedByFeatureApp: App {

    @StateObject private var mainCoordinator: MainCoordinator

    init() {
        let coordinator = MainCoordinator()
        AppComposition.bootstrapFeatures(mainCoordinator: coordinator)
        _mainCoordinator = StateObject(wrappedValue: coordinator)
    }

    var body: some Scene {
        WindowGroup {
            RootView(coordinator: mainCoordinator)
                .onOpenURL { url in
                    guard let destination = DeepLinkRouter.shared.resolve(url: url)
                    else { return }
                    mainCoordinator.handleDeepLinkNavigation(to: destination)
                }
        }
    }
}
