//
//  NavigationHost.swift
//  ModularizedByFeature
//
//  Created by ali alhawas on 31/03/2026.
//

import SwiftUI

/// Hosts an existing navigation flow whose coordinator is owned externally.
///
/// Use this for:
/// - app roots
/// - tab roots
/// - feature entry points
@MainActor
public struct NavigationHost<Root: View>: View {
    @ObservedObject private var coordinator: NavigationCoordinator
    private let root: Root

    public init(
        coordinator: NavigationCoordinator,
        @ViewBuilder root: () -> Root
    ) {
        self.coordinator = coordinator
        self.root = root()
    }

    public var body: some View {
        NavigationStack(path: $coordinator.routes) {
            root
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
