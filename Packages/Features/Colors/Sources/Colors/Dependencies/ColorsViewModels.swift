//
//  ColorsViewModels.swift
//  Colors
//
//  Created by ali alhawas on 24/07/2026.
//

final class ColorsViewModels {

    private let useCases: ColorsUseCases
    private weak var crossFeatureDelegate: ColorsCrossFeatureDelegate?

    init(useCases: ColorsUseCases, crossFeatureDelegate: ColorsCrossFeatureDelegate? = nil) {
        self.useCases = useCases
        self.crossFeatureDelegate = crossFeatureDelegate
    }

    @MainActor
    func makeColorsViewModel() -> ColorsViewModel {
        ColorsViewModel(
            fetchColorsUseCase: useCases.fetchColorsUseCase,
            crossFeatureDelegate: crossFeatureDelegate
        )
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
