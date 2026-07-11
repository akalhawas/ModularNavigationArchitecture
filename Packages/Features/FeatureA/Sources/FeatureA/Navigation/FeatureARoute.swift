//
//  FeatureARoute.swift
//  ModularizedByFeature
//
//  Created by ali alhawas on 07/02/2026.
//

import SwiftUI
import Navigation

public enum FeatureARoute: Route {
    case mainScreen
    case firstScreen
    case secondScreen
    case thirdScreen(id: String)

    public func makeView(coordinator: NavigationCoordinator) -> some View {
        switch self {
        case .mainScreen:
            FeatureAListView().environmentObject(coordinator)
        case .firstScreen:
            FeatureADetailView().environmentObject(coordinator)
        case .secondScreen:
            FeatureASubDetailView().environmentObject(coordinator)
        case .thirdScreen(let id):
            FeatureASubSubDetailView(flightID: id).environmentObject(coordinator)
        }
    }
}
