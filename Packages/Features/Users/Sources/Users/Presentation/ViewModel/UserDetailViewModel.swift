//
//  UserDetailViewModel.swift
//  Users
//
//  Created by ali alhawas on 24/07/2026.
//

import Foundation
import Combine

final class UserDetailViewModel: ObservableObject {

    @Published private(set) var user: User?
    @Published private(set) var errorMessage: String?

    private let userId: Int
    private let fetchUserDetailUseCase: FetchUserDetailUseCase
    private var cancellables = Set<AnyCancellable>()

    init(userId: Int, fetchUserDetailUseCase: FetchUserDetailUseCase) {
        self.userId = userId
        self.fetchUserDetailUseCase = fetchUserDetailUseCase
    }

    func fetchUser() {
        fetchUserDetailUseCase.execute(id: userId)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] response in
                print("DEBUG: \(response)")
                self?.user = response.data
            }
            .store(in: &cancellables)
    }
}
