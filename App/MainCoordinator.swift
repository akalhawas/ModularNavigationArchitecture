//
//  MainCoordinator.swift
//  ModularizedByFeature
//
//  Created by ali alhawas on 24/07/2026.
//

import Combine
import SwiftUI
import Navigation
import Colors
import UsersAPI
@_exported import Users
@_exported import Colors
 
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
        case is UsersDestination:
            guard let route = RouteRegistry.shared.resolve(destination) else { return }
            selectedTab = .home
            homeCoordinator.navigate(to: route, strategy: .resetStack)
            return
        default:
            guard let route = RouteRegistry.shared.resolve(destination) else { return }
            selectedTab = .services
            servicesCoordinator.navigate(to: route, strategy: .resetStack)
        }
    }
}
