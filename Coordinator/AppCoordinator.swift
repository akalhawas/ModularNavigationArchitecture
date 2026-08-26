//
//  AppCoordinator.swift
//  ModularNavigationExample
//
//  Created by ali alhawas on 24/07/2026.
//

import Combine
import SwiftUI

@MainActor
final class AppCoordinator: ObservableObject {

    @Published var selectedTab: TabBar = .home

    let homeCoordinator = NavigationCoordinator()
    let servicesCoordinator = NavigationCoordinator()

    private var allCoordinators: [NavigationCoordinator] {
        [homeCoordinator, servicesCoordinator]
    }

    init() { }

}

// MARK: Feature Deeplink Handler
extension AppCoordinator {
    func handleDeepLinkNavigation(to route: AnyRoute) {

        /// remove all presentation
        allCoordinators.forEach { coordinator in
            coordinator.dismissSheet()
            coordinator.dismissFullScreen()
        }

        selectedTab = .services
        servicesCoordinator.navigate(to: route, strategy: .resetStack)
    }
}

// MARK: Colors Cross-feature
extension AppCoordinator: ColorsCrossFeatureDelegate {
    func onPrimaryAction(coordinator: NavigationCoordinator, id: Int, onReturn: @escaping () -> Void) {
        coordinator.navigate(to: UsersRoute.userDetail(id: id, onDetailAction: onReturn), strategy: .push)
    }
}
