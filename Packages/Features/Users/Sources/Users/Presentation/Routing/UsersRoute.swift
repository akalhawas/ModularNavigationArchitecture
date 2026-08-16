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
    case userDetail(id: Int)

    public func makeView(coordinator: NavigationCoordinator) -> some View {
        switch self {
        case .usersList:
            UsersView(viewModel: UsersModule.viewModels().makeUsersViewModel())
                .environmentObject(coordinator)
        case .userDetail(let id):
            UserDetailView(viewModel: UsersModule.viewModels().makeUserDetailViewModel(userId: id))
                .environmentObject(coordinator)
        }
    }
}
