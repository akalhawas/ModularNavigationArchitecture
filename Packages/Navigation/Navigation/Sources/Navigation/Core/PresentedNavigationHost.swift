//
//  PresentedNavigationHost.swift
//  ModularizedByFeature
//
//  Created by ali alhawas on 31/03/2026.
//

import SwiftUI

/// Hosts a newly presented navigation flow with its own internal coordinator.
///
/// Use this for:
/// - sheet flows
/// - full-screen flows
/// - nested modal navigation
public struct PresentedNavigationHost: View {
    @StateObject private var coordinator = NavigationCoordinator()
    private let route: AnyRoute

    public init(route: AnyRoute) {
        self.route = route
    }

    public var body: some View {
        NavigationStack(path: $coordinator.routes) {
            route
                .makeView(coordinator: coordinator)
                .navigationDestination(for: AnyRoute.self) { route in
                    route.makeView(coordinator: coordinator)
                }
                .sheet(item: $coordinator.sheetItem) { item in
                    PresentedNavigationHost(route: item.route)
                        .presentationDetents(item.configuration.detents)
                        .presentationDragIndicator(.visible)
                }
#if os(iOS)
                .fullScreenCover(item: $coordinator.fullScreenRoute) { route in
                    PresentedNavigationHost(route: route)
                }
#endif
        }
    }
}
