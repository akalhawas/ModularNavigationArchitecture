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

    let crossFeatureActions: ColorsCrossFeatureActions

    private let fetchColorsUseCase: FetchColorsUseCase
    private var cancellables = Set<AnyCancellable>()

    init(fetchColorsUseCase: FetchColorsUseCase, crossFeatureActions: ColorsCrossFeatureActions) {
        self.fetchColorsUseCase = fetchColorsUseCase
        self.crossFeatureActions = crossFeatureActions
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

    /// Called when the secondary-action screen this feature navigated into
    /// reports its own action happened. Fill in whatever Colors needs to do
    /// in response.
    func didReturnFromSecondaryAction() {
        print("DEBUG: didReturnFromSecondaryAction")
    }
}
