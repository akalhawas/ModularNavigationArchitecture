//
//  NavigationCoordinator.swift
//  ModularizedByFeature
//
//  Created by ali alhawas on 31/03/2026.
//

import SwiftUI
import Combine

/// Manages navigation state for a single navigation flow.
///
/// Use one coordinator per independent navigation stack.
/// - For root or tab flows: inject and own it from outside.
/// - For presented modal flows: create a fresh coordinator internally.
public final class NavigationCoordinator: ObservableObject {
    
    @Published public var routes: [AnyRoute] = []
    @Published public var fullScreenRoute: AnyRoute?
    @Published public var sheetItem: PresentedSheetRoute?

    /// Set by a parent coordinator to handle navigation that should escape this stack (e.g. hide tab bar).
    public var navigateToMain: ((AnyRoute) -> Void)?

    public init() {}

    /// Navigates to the specified route using the given navigation strategy.
    ///
    /// - Parameters:
    ///   - route: The destination route to navigate to.
    ///   - strategy: The navigation behavior used to reach the destination.
    ///     Defaults to `.push`.
    public func navigate(to route: AnyRoute, strategy: NavigationStrategy = .push) {
        switch strategy {

        case .push:
            pushAny(route)

        case .resetStack:
            routes = [route]

        case .popToIfExists:
            if let index = routes.firstIndex(where: { $0 == route }) {
                routes = Array(routes.prefix(index + 1))
            } else {
                pushAny(route)
            }
        }
    }
    
    /// Navigates to the specified route using the given navigation strategy.
    ///
    /// - Parameters:
    ///   - route: The strongly typed route to navigate to.
    ///   - strategy: The navigation behavior used to reach the destination.
    ///     Defaults to `.push`.
    public func navigate<R: Route>(
        to route: R,
        strategy: NavigationStrategy = .push
    ) {
        navigate(
            to: AnyRoute(route),
            strategy: strategy
        )
    }

    // MARK: - Push

    /// Pushes a new route onto the current navigation stack.
    private func push<R: Route>(_ route: R) {
        routes.append(AnyRoute(route))
    }

    /// Pushes an already type-erased route onto the current navigation stack.
    private func pushAny(_ route: AnyRoute) {
        routes.append(route)
    }

    // MARK: - Pop

    /// Pops the top-most route from the current navigation stack. + back N screens
    public func pop(count: Int? = 1) {
        let count = max(count ?? 1, 1)
        guard !routes.isEmpty else { return }
        routes.removeLast(min(count, routes.count))
    }

    /// Pops the navigation stack back to the last route matching the predicate.
    public func popTo(where predicate: (AnyRoute) -> Bool) {
        guard let index = routes.lastIndex(where: predicate) else { return }
        routes = Array(routes.prefix(index + 1))
    }
    
    /// Pops all pushed routes and returns to the root screen.
    public func popToRoot() {
        routes.removeAll()
    }
    
    // MARK: - Present

    /// Presents a route as a sheet.
    public func presentSheet<R: Route>(
        _ route: R,
        detents: Set<PresentationDetent>? = nil
    ) {
        let anyRoute = AnyRoute(route)
        sheetItem = PresentedSheetRoute(
            route: anyRoute,
            configuration: SheetConfiguration(detents: detents ?? route.sheetDetents)
        )
    }

    /// Presents a route as a full-screen cover.
    public func presentFullScreen<R: Route>(_ route: R) {
        fullScreenRoute = AnyRoute(route)
    }

    // MARK: - Dismiss
    
    /// Dismisses the currently presented sheet.
    public func dismissSheet() {
        sheetItem = nil
    }

    /// Dismisses the currently presented full-screen cover.
    public func dismissFullScreen() {
        fullScreenRoute = nil
    }
}

/// Defines how a navigation request should be performed.
public enum NavigationStrategy {

    /// Pushes the destination onto the current navigation stack.
    case push

    /// Pops back to the destination if it already exists in the stack;
    /// otherwise pushes it as a new destination.
    case popToIfExists

    /// Clears the current navigation stack and starts a new stack
    /// with the specified destination.
    case resetStack
}
