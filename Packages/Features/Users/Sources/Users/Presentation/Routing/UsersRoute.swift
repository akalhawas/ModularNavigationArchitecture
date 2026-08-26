//
//  UsersRoute.swift
//  Users
//
//  Created by ali alhawas on 24/07/2026.
//

import SwiftUI
import Navigation

public enum UsersRoute: Route {
    case usersList
    case userDetail(id: Int, onDetailAction: ActionCallback<Void>? = nil)

    public static func userDetail(id: Int, onDetailAction: @escaping () -> Void) -> UsersRoute {
        .userDetail(id: id, onDetailAction: ActionCallback(onDetailAction))
    }

    public func makeView(coordinator: NavigationCoordinator) -> some View {
        switch self {
        case .usersList:
            UsersView(viewModel: UsersModule.viewModels().makeUsersViewModel())
                .environmentObject(coordinator)
        case .userDetail(let id, let onDetailAction):
            UserDetailView(
                viewModel: UsersModule.viewModels().makeUserDetailViewModel(
                    userId: id,
                    onDetailAction: onDetailAction
                )
            )
            .environmentObject(coordinator)
        }
    }
}
