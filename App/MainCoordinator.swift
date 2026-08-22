//
//  MainCoordinator.swift
//  ModularizedByFeature
//
//  Created by ali alhawas on 24/07/2026.
//

import Combine
import SwiftUI
 
@MainActor
final class MainCoordinator: ObservableObject {

    @Published var selectedTab: TabBar = .home
    @Published var isTabBarHidden: Bool = false

    let homeCoordinator = NavigationCoordinator()
    let servicesCoordinator = NavigationCoordinator()

    init() { }

}

// MARK: Feature Deeplink
extension MainCoordinator {
    func handleDeepLinkNavigation(to destination: any NavigationDestination) {
        switch destination {
        default:
            guard let route = RouteRegistry.shared.resolve(destination) else { return }
            selectedTab = .services
            servicesCoordinator.dismissSheet()
            servicesCoordinator.dismissFullScreen()
            servicesCoordinator.navigate(to: route, strategy: .push)
        }
    }
}
