//
//  ColorsRoute.swift
//  Colors
//
//  Created by ali alhawas on 24/07/2026.
//

import SwiftUI
import Navigation

public enum ColorsRoute: Route {
    case colorsList
    case colorDetail(id: Int)

    public func makeView(coordinator: NavigationCoordinator) -> some View {
        switch self {
        case .colorsList:
            ColorsView(viewModel: ColorsModule.viewModels().makeColorsViewModel())
                .environmentObject(coordinator)
        case .colorDetail(let id):
            ColorDetailView(viewModel: ColorsModule.viewModels().makeColorDetailViewModel(colorId: id))
                .environmentObject(coordinator)
        }
    }
}
