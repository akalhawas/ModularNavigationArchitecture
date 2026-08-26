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

    weak var crossFeatureDelegate: ColorsCrossFeatureDelegate?

    private let fetchColorsUseCase: FetchColorsUseCase
    private var cancellables = Set<AnyCancellable>()

    init(fetchColorsUseCase: FetchColorsUseCase, crossFeatureDelegate: ColorsCrossFeatureDelegate?) {
        self.fetchColorsUseCase = fetchColorsUseCase
        self.crossFeatureDelegate = crossFeatureDelegate
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

    func didReturnFromSecondaryAction() {
        colors = colors.dropLast()
        print("DEBUG: didReturnFromSecondaryAction")
    }

    /// Same idea as `didReturnFromSecondaryAction()`, for the delegate-driven
    /// seam instead of the closure-driven one.
    func didReturnFromTertiaryAction() {
        colors = colors.dropLast()
        print("DEBUG: didReturnFromTertiaryAction")
    }
}
