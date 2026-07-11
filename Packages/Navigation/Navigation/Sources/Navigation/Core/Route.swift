//
//  Route.swift
//  ModularizedByFeature
//
//  Created by ali alhawas on 31/03/2026.
//

import SwiftUI

/// Represents a navigable destination in the app.
///
/// Conforming types define:
/// - how to build their screen
/// - optional sheet presentation configuration
public protocol Route: Hashable {
    associatedtype Screen: View

    /// Builds the destination view for this route.
    @MainActor
    @ViewBuilder
    func makeView(coordinator: NavigationCoordinator) -> Screen

    /// Sheet detent configuration used when this route is presented via
    /// `presentSheet` without explicit `detents`.
    ///
    /// Declared as a protocol requirement (rather than only an extension
    /// member) so a conforming type's override is actually honored when
    /// accessed through generic `Route`-constrained code, e.g. `AnyRoute`
    /// and `NavigationCoordinator.presentSheet`.
    var sheetDetents: Set<PresentationDetent> { get }
}

public extension Route {
    /// Default sheet detent configuration.
    var sheetDetents: Set<PresentationDetent> { [.large] }
}
