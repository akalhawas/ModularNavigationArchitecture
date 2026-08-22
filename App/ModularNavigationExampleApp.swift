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

    @StateObject var mainCoordinator = MainCoordinator()

    init() {
        AppComposition.bootstrapFeatures()
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
