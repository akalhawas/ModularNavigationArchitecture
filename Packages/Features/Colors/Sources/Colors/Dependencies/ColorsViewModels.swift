//
//  ColorsViewModels.swift
//  Colors
//
//  Created by ali alhawas on 24/07/2026.
//

final class ColorsViewModels {

    private let useCases: ColorsUseCases

    init(useCases: ColorsUseCases) {
        self.useCases = useCases
    }

    @MainActor
    func makeColorsViewModel() -> ColorsViewModel {
        ColorsViewModel(fetchColorsUseCase: useCases.fetchColorsUseCase)
    }

    @MainActor
    func makeColorDetailViewModel(colorId: Int) -> ColorDetailViewModel {
        ColorDetailViewModel(colorId: colorId, fetchColorDetailUseCase: useCases.fetchColorDetailUseCase)
    }

    @MainActor
    func makeLatestColorsViewModel(limit: Int = 10) -> LatestColorsViewModel {
        LatestColorsViewModel(fetchColorsUseCase: useCases.fetchColorsUseCase, limit: limit)
    }
}
