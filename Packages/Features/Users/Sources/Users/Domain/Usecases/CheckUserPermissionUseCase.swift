//
//  CheckUserPermissionUseCase.swift
//  Users
//
//  Created by ali alhawas on 25/08/2026.
//

import Combine

protocol CheckUserPermissionUseCase {
    func execute(userId: Int) -> AnyPublisher<Bool, Error>
}

final class CheckUserPermissionUseCaseImp: CheckUserPermissionUseCase {

    private let repository: UserRepository

    init(repository: UserRepository) {
        self.repository = repository
    }

    func execute(userId: Int) -> AnyPublisher<Bool, Error> {
        repository.checkPermission(userId: userId)
    }
}
