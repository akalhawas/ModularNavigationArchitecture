//
//  AnyRoute.swift
//  ModularizedByFeature
//
//  Created by ali alhawas on 31/03/2026.
//

import SwiftUI

/// Type-erased wrapper around any `Route`.
///
/// `AnyRoute` allows heterogeneous route types to be stored
/// in a single navigation stack.
public struct AnyRoute: Hashable, Identifiable {

    /// Stable identity for SwiftUI presentation APIs.
    public let id: UUID = UUID()
    private let hash: AnyHashable
    private let box: AnyHashable
    private let viewBox: any AnyRouteBoxing

    /// Sheet detents captured before type erasure.
    public let sheetDetents: Set<PresentationDetent>

    /// Wraps a concrete route in a type-erased container.
    ///
    /// Plain, non-isolated construction: only the captured `RouteBox`'s stored
    /// `route` value is retained here. No view gets built, and nothing requires
    /// the main actor, until `makeView` is actually called.
    public init<R: Route>(_ route: R) {
        self.hash = route
        self.box = AnyHashable(route)
        self.viewBox = RouteBox(route: route)
        self.sheetDetents = route.sheetDetents
    }

    /// Builds the destination view for the wrapped route.
    @MainActor
    public func makeView(coordinator: NavigationCoordinator) -> some View {
        viewBox.makeView(coordinator: coordinator)
    }

    /// Hashes the wrapped route for use in navigation paths.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(hash)
    }
    /// Returns a Boolean value indicating whether two wrapped routes are equal.
    public static func == (lhs: AnyRoute, rhs: AnyRoute) -> Bool {
        lhs.hash == rhs.hash
    }

    /// Returns a Boolean value indicating whether the wrapped route matches the specified route.
    public func matches<R: Route>(_ route: R) -> Bool {
        box == AnyHashable(route)
    }
}

/// Private erasure boundary: holds a concrete `Route` without erasing it into a
/// `@MainActor`-isolated closure at construction time. Only `makeView` — the one
/// operation that actually requires the main actor — is isolated.
private protocol AnyRouteBoxing {
    @MainActor
    func makeView(coordinator: NavigationCoordinator) -> AnyView
}

private struct RouteBox<R: Route>: AnyRouteBoxing {
    let route: R

    @MainActor
    func makeView(coordinator: NavigationCoordinator) -> AnyView {
        AnyView(route.makeView(coordinator: coordinator))
    }
}
