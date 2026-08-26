//
//  ColorsModule.swift
//  Colors
//
//  Created by ali alhawas on 24/08/2026.
//

import NetworkService
import Navigation
import SwiftUI

/// Resolves this feature's dependencies without callers having to build
/// `ColorsDependencies` themselves at every navigation site.
///
/// Must be configured once at app launch (see `AppComposition.bootstrapFeatures`)
/// before any `ColorsRoute` is navigated to.
@MainActor
public enum ColorsModule {

    static var viewModels: () -> ColorsViewModels = {
        fatalError("ColorsModule not registered — call ColorsModule.register(network:crossFeatureActions:crossFeatureDelegate:) at app launch")
    }

    public static func register(network: NetworkService, crossFeatureDelegate: ColorsCrossFeatureDelegate? = nil) {
        let dependencies = ColorsDependencies(network: network, crossFeatureDelegate: crossFeatureDelegate)
        viewModels = { dependencies.viewModels }
        registerRouting()
    }

    private static func registerRouting() {
        DeepLinkRouter.shared.register(ColorsDeepLinkMapper())
    }
    
    @ViewBuilder
    public static func headerHomeView(items: Int) -> some View {
        LatestColorsView(viewModel: viewModels().makeLatestColorsViewModel(limit: items))
    }
}
