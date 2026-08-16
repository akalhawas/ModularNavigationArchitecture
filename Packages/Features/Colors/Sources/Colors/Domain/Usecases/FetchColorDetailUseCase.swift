//
//  FetchColorDetailUseCase.swift
//  Colors
//
//  Created by ali alhawas on 24/07/2026.
//

import Combine

protocol FetchColorDetailUseCase {
    func execute(id: Int) -> AnyPublisher<ColorDetailResponse, Error>
}

final class FetchColorDetailUseCaseImp: FetchColorDetailUseCase {

    private let repository: ColorRepository

    init(repository: ColorRepository) {
        self.repository = repository
    }

    func execute(id: Int) -> AnyPublisher<ColorDetailResponse, Error> {
        repository.fetchColor(id: id)
    }
}
