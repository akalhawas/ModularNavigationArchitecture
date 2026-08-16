//
//  ColorsUseCases.swift
//  Colors
//
//  Created by ali alhawas on 24/07/2026.
//

final class ColorsUseCases {

    private let repositories: ColorsRepositories

    init(repositories: ColorsRepositories) {
        self.repositories = repositories
    }

    lazy var fetchColorsUseCase: FetchColorsUseCase = FetchColorsUseCaseImp(
        repository: repositories.colorsRepository
    )

    lazy var fetchColorDetailUseCase: FetchColorDetailUseCase = FetchColorDetailUseCaseImp(
        repository: repositories.colorsRepository
    )
}
