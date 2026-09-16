//
//  ColorsViewModel.swift
//  Colors
//
//  Created by ali alhawas on 24/07/2026.
//

import Foundation
import Combine
import Navigation

@MainActor
final class ColorsViewModel: ObservableObject {

    @Published private(set) var colors: [AppColor] = []
    @Published private(set) var errorMessage: String?

    weak var crossFeatureDelegate: ColorsCrossFeatureDelegate?

    private let fetchColorsUseCase: FetchColorsUseCase
    private var cancellables = Set<AnyCancellable>()
    private let router: ColorsRouting
    
    enum ColorsAction {
        case navigateToDetails(id: Int)
        case navigateToUserDetails(id: Int)
    }
    
    init(fetchColorsUseCase: FetchColorsUseCase, crossFeatureDelegate: ColorsCrossFeatureDelegate?, router: ColorsRouting) {
        self.fetchColorsUseCase = fetchColorsUseCase
        self.crossFeatureDelegate = crossFeatureDelegate
        self.router = router
    }

    func trigger(action: ColorsAction){
        switch action {
        case .navigateToDetails(let id):
            navigateToDetails(id: id)
        case .navigateToUserDetails(let id):
            navigateToUserDetails(id: id)
        }
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

    func didReturnFromAction() {
        print("DEBUG: didReturnFromAction")
        colors = colors.dropLast()
    }
    
    func navigateToDetails(id: Int) {
        router.showColorDetail(id: id)
    }
    
    func navigateToUserDetails(id: Int) {
        router.showUsers(id: id) {
            // Completeion
        }
    }
}
