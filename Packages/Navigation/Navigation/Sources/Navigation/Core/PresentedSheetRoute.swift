//
//  PresentedSheetRoute.swift
//  ModularizedByFeature
//
//  Created by ali alhawas on 01/04/2026.
//

import SwiftUI

/// Wraps a route presented modally with an isolated navigation stack.
///
/// Each instance owns its own `NavigationCoordinator`.
public struct PresentedSheetRoute: Identifiable, Equatable {
    public let id = UUID()
    public let route: AnyRoute
    public let configuration: SheetConfiguration

    public init(route: AnyRoute, configuration: SheetConfiguration) {
        self.route = route
        self.configuration = configuration
    }
}
