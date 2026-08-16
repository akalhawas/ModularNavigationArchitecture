//
//  LatestColorsViewModel.swift
//  Colors
//

import Foundation
import Combine

final class LatestColorsViewModel: ObservableObject {

    @Published private(set) var colors: [AppColor] = []
    @Published private(set) var errorMessage: String?

    private let fetchColorsUseCase: FetchColorsUseCase
    private let limit: Int
    private var cancellables = Set<AnyCancellable>()

    init(fetchColorsUseCase: FetchColorsUseCase, limit: Int) {
        self.fetchColorsUseCase = fetchColorsUseCase
        self.limit = limit
    }

    func fetchLatestColors() {
        fetchColorsUseCase.execute(page: 1)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] response in
                guard let self else { return }
                self.colors = Array(response.data.prefix(self.limit))
            }
            .store(in: &cancellables)
    }
}
