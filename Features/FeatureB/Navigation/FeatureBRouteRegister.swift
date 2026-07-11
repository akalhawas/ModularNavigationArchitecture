//
//  FeatureBRouteRegister.swift
//  ModularizedByFeature
//
//  Created by ali alhawas on 31/03/2026.
//

import SwiftUI
import Navigation
import NavigationDestinations

public enum FeatureBModule: FeatureModule {
    public static func register() {
        FeatureBRegisteration.routeRegister()
    }
}

public enum FeatureBRegisteration {
    public static func routeRegister() {
        RouteRegistry.shared.register(FeatureBDestination.self) { destination in
            switch destination {
            case .mainScreen:
                return AnyRoute(FeatureBRoute.mainScreen)
            case .thirdScreen(let id):
                return AnyRoute(FeatureBRoute.thirdScreen(id: id))
            @unknown default:
                fatalError("Unhandled destination: \(destination)")
            }
        }
    }
}
