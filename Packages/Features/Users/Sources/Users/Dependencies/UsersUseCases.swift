//
//  UsersUseCases.swift
//  Users
//
//  Created by ali alhawas on 23/07/2026.
//

final class UsersUseCases {

    private let repositories: UsersRepositories

    init(repositories: UsersRepositories) {
        self.repositories = repositories
    }

    lazy var fetchUsersUseCase: FetchUsersUseCase = FetchUsersUseCaseImp(
        repository: repositories.usersRepository
    )

    lazy var fetchUserDetailUseCase: FetchUserDetailUseCase = FetchUserDetailUseCaseImp(
        repository: repositories.usersRepository
    )
}
