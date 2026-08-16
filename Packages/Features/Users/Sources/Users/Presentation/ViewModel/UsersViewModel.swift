//
//  UsersViewModel.swift
//  Users
//
//  Created by ali alhawas on 24/07/2026.
//

import Foundation
import Combine

final class UsersViewModel: ObservableObject {

    @Published private(set) var users: [User] = []
    @Published private(set) var errorMessage: String?

    private let fetchUsersUseCase: FetchUsersUseCase
    private var cancellables = Set<AnyCancellable>()

    init(fetchUsersUseCase: FetchUsersUseCase) {
        self.fetchUsersUseCase = fetchUsersUseCase
    }

    func fetchUsers(page: Int = 1) {
        fetchUsersUseCase.execute(page: page)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] response in
                print("DEBUG: \(response)")
                self?.users = response.data
            }
            .store(in: &cancellables)
    }
}
