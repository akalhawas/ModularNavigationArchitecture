//
//  LatestUsersViewModel.swift
//  Users
//

import Foundation
import Combine

final class LatestUsersViewModel: ObservableObject {

    @Published private(set) var users: [User] = []
    @Published private(set) var errorMessage: String?

    private let fetchUsersUseCase: FetchUsersUseCase
    private let limit: Int
    private var cancellables = Set<AnyCancellable>()

    init(fetchUsersUseCase: FetchUsersUseCase, limit: Int) {
        self.fetchUsersUseCase = fetchUsersUseCase
        self.limit = limit
    }

    func fetchLatestUsers() {
        fetchUsersUseCase.execute(page: 1)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] response in
                guard let self else { return }
                self.users = Array(response.data.prefix(self.limit))
            }
            .store(in: &cancellables)
    }
}
