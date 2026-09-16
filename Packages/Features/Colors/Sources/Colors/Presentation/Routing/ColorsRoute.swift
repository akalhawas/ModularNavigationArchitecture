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

    public func makeView(router: NavigationRouter) -> some View {
        switch self {
        case .colorsList:
            ColorsView(viewModel: ColorsModule.viewModels().makeColorsViewModel(router: router))
        case .colorDetail(let id):
            ColorDetailView(viewModel: ColorsModule.viewModels().makeColorDetailViewModel(colorId: id))
        }
    }
}

@MainActor
protocol ColorsRouting {
    func showColorDetail(id: Int)
    func showUsers(id: Int, onReturn: @escaping () -> Void)
}

@MainActor
struct ColorsRouter: ColorsRouting {
    let router: NavigationRouter
    weak var crossFeatureDelegate: ColorsCrossFeatureDelegate?

    func showColorDetail(id: Int) {
        router.navigate(to: ColorsRoute.colorDetail(id: id))
    }
    
    func showUsers(id: Int, onReturn: @escaping () -> Void) {
        crossFeatureDelegate?.onPrimaryAction(router: router, id: id, onReturn: onReturn)
    }
}
