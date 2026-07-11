//
//  ModularNavigationExampleApp.swift
//  ModularNavigationExample
//
//  Created by ali alhawas on 10/07/2026.
//

import SwiftUI
import FeatureB
import Navigation
import NavigationDestinations
import Combine

@main
struct ModularizedByFeatureApp: App {

    @StateObject var mainCoordinator = MainCoordinator()

    init() {
        AppComposition.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            RootView(coordinator: mainCoordinator)
                .onOpenURL { url in
                    guard let destination = AppComposition.deepLinkRouter.resolve(url: url)
                    else { return }
                    mainCoordinator.handleExternalNavigation(to: destination)
                }
        }
    }
}

enum AppComposition {
    // MARK: - Route Registration
    // Uses the FeatureModule abstraction so the app configures modules without knowing their implementation.
    static let modules: [FeatureModule.Type] = [
        FeatureBModule.self,
    ]

    static func configure() {
        modules.forEach { $0.register() }
    }
    
    // MARK: - Deeplink
    public static let deepLinkRouter = DeepLinkRouter(
        mappers: [
            FeatureBDeepLinkMapper()
        ]
    )
}

final class MainCoordinator: ObservableObject {

    @Published var selectedTab: TabBar = .home
    @Published var isTabBarHidden: Bool = false

    let homeCoordinator = NavigationCoordinator()
    let servicesCoordinator = NavigationCoordinator()

    init() { }

    func handleExternalNavigation(to destination: any NavigationDestination) {
        let route = RouteRegistry.shared.resolve(destination)

        switch destination {
        case is FeatureBDestination:
            selectedTab = .services
            servicesCoordinator.navigate(to: route, strategy: .resetStack)
        default:
            break
        }
    }
}
