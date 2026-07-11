//
//  FeatureBRoutes.swift
//  ModularizedByFeature
//
//  Created by ali alhawas on 02/01/2026.
//

import SwiftUI
import Navigation

public enum FeatureBRoute: Route {
    case mainScreen
    case firstScreen
    case secondScreen
    case thirdScreen(id: String)

    public func makeView(coordinator: NavigationCoordinator) -> some View {
        switch self {
        case .mainScreen:
            FeatureBListView().environmentObject(coordinator)
        case .firstScreen:
            FeatureBDetailView().environmentObject(coordinator)
        case .secondScreen:
            FeatureBSubDetailView().environmentObject(coordinator)
        case .thirdScreen(let id):
            FeatureBSubSubDetailView(flightID: id).environmentObject(coordinator)
        }
    }
}
