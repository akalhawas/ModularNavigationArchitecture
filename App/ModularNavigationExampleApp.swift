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
struct ModularNavigationExampleApp: App {

    @StateObject private var appCoordinator: AppCoordinator

    init() {
        let coordinator = AppCoordinator()
        AppComposition.bootstrapFeatures(appCoordinator: coordinator)
        _appCoordinator = StateObject(wrappedValue: coordinator)
    }

    var body: some Scene {
        WindowGroup {
            TabBarView(appCoordinator: appCoordinator)
                .onOpenURL { url in
                    guard let route = DeepLinkRouter.shared.resolve(url: url)
                    else { return }
                    appCoordinator.handleDeepLinkNavigation(to: route)
                }
        }
    }
}
