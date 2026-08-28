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

    let homeRouter = NavigationRouter()
    let servicesRouter = NavigationRouter()

    private var allRouters: [NavigationRouter] {
        [homeRouter, servicesRouter]
    }

    init() { }

}

// MARK: Feature Deeplink Handler
extension AppCoordinator {
    func handleDeepLinkNavigation(to route: AnyRoute) {

        /// remove all presentation
        allRouters.forEach { router in
            router.dismissSheet()
            router.dismissFullScreen()
        }

        selectedTab = .services
        servicesRouter.navigate(to: route, strategy: .resetStack)
    }
}

// MARK: In App Colors Cross-feature
extension AppCoordinator: ColorsCrossFeatureDelegate {
    func onPrimaryAction(router: NavigationRouter, id: Int) {
        router.navigate(to: UsersRoute.userDetail(id: id), strategy: .push)
    }
}
