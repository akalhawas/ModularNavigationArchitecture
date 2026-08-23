//
//  ColorsViewModel.swift
//  Colors
//
//  Created by ali alhawas on 24/07/2026.
//

import Foundation
import Combine

final class ColorsViewModel: ObservableObject {

    @Published private(set) var colors: [AppColor] = []
    @Published private(set) var errorMessage: String?

    private let fetchColorsUseCase: FetchColorsUseCase
    private var cancellables = Set<AnyCancellable>()

    init(fetchColorsUseCase: FetchColorsUseCase) {
        self.fetchColorsUseCase = fetchColorsUseCase
    }

    func fetchColors(page: Int = 1) {
        fetchColorsUseCase.execute(page: page)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] response in
                self?.colors = response.data
            }
            .store(in: &cancellables)
    }

    /// Passed as `UsersDestination.details(id:onDetailAction:)`'s callback.
    /// Called directly by `UserDetailViewModel.notifyDetailAction()` when
    /// its own action happens — independent of whether/when the user has
    /// actually navigated back to this screen. Fill in whatever Colors
    /// needs to do in response.
    func didReturnFromUsers() {
        
    }
}
