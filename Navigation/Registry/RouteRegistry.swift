//
//  RouteRegistry.swift
//  ModularizedByFeature
//
//  Created by ali alhawas on 31/03/2026.
//

import SwiftUI

/// Maps `NavigationDestination` to `AnyRoute` using registered builders.
///
/// Enables cross-feature navigation without direct feature dependencies.
public final class RouteRegistry {
    
    /// Shared registry instance.
    public static let shared = RouteRegistry()
    
    public init() {}

    private var builders: [ObjectIdentifier: (Any) -> AnyRoute?] = [:]

    /// Registers a destination type and its corresponding route builder.
    public func register<D: NavigationDestination>(
        _ type: D.Type,
        builder: @escaping (D) -> AnyRoute
    ) {
        builders[ObjectIdentifier(type)] = { destination in
            guard let typedDestination = destination as? D else {
                assertionFailure("Invalid destination type: \(destination)")
                return nil
            }
            return builder(typedDestination)
        }
    }
    
    /// Resolves a destination into its corresponding route.
    public func resolve<D: NavigationDestination>(_ destination: D) -> AnyRoute {
        guard let route = builders[ObjectIdentifier(D.self)]?(destination) else {
            fatalError("No route registered for \(D.self)")
        }
        return route
    }
}

/// Defines a feature module that registers its navigation configuration.
public protocol FeatureModule {
    /// Registers routes and other feature navigation components.
    static func register()
}
