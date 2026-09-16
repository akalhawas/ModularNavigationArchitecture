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
    case userDetail(id: Int, onDismiss: ActionCallback<Void>? = nil)

    public static func userDetail(id: Int, onDismiss: @escaping () -> Void) -> UsersRoute {
        .userDetail(id: id, onDismiss: ActionCallback(onDismiss))
    }

    public func makeView(router: NavigationRouter) -> some View {
        switch self {
        case .usersList:
            UsersView(viewModel: UsersModule.viewModels().makeUsersViewModel())
        case .userDetail(let id, let onDismiss):
            UserDetailView(viewModel: UsersModule.viewModels().makeUserDetailViewModel(userId: id, onDismiss: onDismiss))
        }
    }
}
