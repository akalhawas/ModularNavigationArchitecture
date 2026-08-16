//
//  FetchColorsUseCase.swift
//  Colors
//
//  Created by ali alhawas on 24/07/2026.
//

import Combine

protocol FetchColorsUseCase {
    func execute(page: Int) -> AnyPublisher<ColorListResponse, Error>
}

final class FetchColorsUseCaseImp: FetchColorsUseCase {

    private let repository: ColorRepository

    init(repository: ColorRepository) {
        self.repository = repository
    }

    func execute(page: Int) -> AnyPublisher<ColorListResponse, Error> {
        repository.fetchColors(page: page)
    }
}
