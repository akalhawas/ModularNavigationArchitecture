//
//  UserDetailViewModel.swift
//  Users
//
//  Created by ali alhawas on 24/07/2026.
//

import Foundation
import Combine
import Navigation

final class UserDetailViewModel: ObservableObject {

    @Published private(set) var user: User?
    @Published private(set) var errorMessage: String?

    private let userId: Int
    private let fetchUserDetailUseCase: FetchUserDetailUseCase
    private let onDetailAction: ActionCallback<Void>?
    private var cancellables = Set<AnyCancellable>()

    init(
        userId: Int,
        fetchUserDetailUseCase: FetchUserDetailUseCase,
        onDetailAction: ActionCallback<Void>? = nil
    ) {
        self.userId = userId
        self.fetchUserDetailUseCase = fetchUserDetailUseCase
        self.onDetailAction = onDetailAction
    }

    /// Call this from wherever the actual action happens on this screen —
    /// it's independent of navigation; it doesn't pop or dismiss anything,
    /// it just notifies whoever navigated in here, if they asked to know.
    func notifyDetailAction() {
        onDetailAction?.fire()
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
