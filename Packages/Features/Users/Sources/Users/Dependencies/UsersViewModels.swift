//
//  UsersViewModels.swift
//  Users
//
//  Created by ali alhawas on 24/07/2026.
//

import Navigation

final class UsersViewModels {

    private let useCases: UsersUseCases

    init(useCases: UsersUseCases) {
        self.useCases = useCases
    }

    @MainActor
    func makeUsersViewModel() -> UsersViewModel {
        UsersViewModel(fetchUsersUseCase: useCases.fetchUsersUseCase)
    }

    @MainActor
    func makeUserDetailViewModel(userId: Int, onDetailAction: ActionCallback<Void>? = nil) -> UserDetailViewModel {
        UserDetailViewModel(
            userId: userId,
            fetchUserDetailUseCase: useCases.fetchUserDetailUseCase,
            onDetailAction: onDetailAction
        )
    }
}
