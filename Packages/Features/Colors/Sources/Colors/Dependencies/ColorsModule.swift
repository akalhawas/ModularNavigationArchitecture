//
//  ColorsModule.swift
//  Colors
//
//  Created by ali alhawas on 24/07/2026.
//

import SwiftUI
import NetworkService
import Navigation
import ColorsAPI

/// Resolves this feature's dependencies without callers having to build
/// `ColorsDependencies` themselves at every navigation site.
///
/// Must be configured once at app launch (see `AppBootstrap.register()`)
/// before any `ColorsRoute` is navigated to.
@MainActor
public enum ColorsModule {

    static var viewModels: () -> ColorsViewModels = {
        fatalError("ColorsModule not registered — call ColorsModule.register(network:) at app launch")
    }

    public static func register(network: NetworkService) {
        let dependencies = ColorsDependencies(network: network)
        viewModels = { dependencies.viewModels }
        registerPublicEntryPoint()
    }

    /// Reusable "latest colors".
    public static func makeLatestColorsView(limit: Int = 10) -> some View {
        LatestColorsView(viewModel: viewModels().makeLatestColorsViewModel(limit: limit))
    }
}

extension ColorsModule {
    static func registerPublicEntryPoint() {
        // MARK: Register the public entry points
        RouteRegistry.shared.register(ColorsDestination.self) { destination in
            switch destination {
            case .details(let id):
                return AnyRoute(ColorsRoute.colorDetail(id: id))
            }
        }
    }
}
