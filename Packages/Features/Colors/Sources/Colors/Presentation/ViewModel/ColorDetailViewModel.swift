//
//  ColorDetailViewModel.swift
//  Colors
//
//  Created by ali alhawas on 24/07/2026.
//

import Foundation
import Combine

final class ColorDetailViewModel: ObservableObject {

    @Published private(set) var color: AppColor?
    @Published private(set) var errorMessage: String?

    private let colorId: Int
    private let fetchColorDetailUseCase: FetchColorDetailUseCase
    private var cancellables = Set<AnyCancellable>()

    init(colorId: Int, fetchColorDetailUseCase: FetchColorDetailUseCase) {
        self.colorId = colorId
        self.fetchColorDetailUseCase = fetchColorDetailUseCase
    }

    func fetchColor() {
        fetchColorDetailUseCase.execute(id: colorId)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] response in
                self?.color = response.data
            }
            .store(in: &cancellables)
    }
}
