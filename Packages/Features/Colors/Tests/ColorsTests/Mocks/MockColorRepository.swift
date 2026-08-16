//
//  MockColorRepository.swift
//  ColorsTests
//

import Combine
@testable import Colors

final class MockColorRepository: ColorRepository {

    var colorsResult: Result<ColorListResponse, Error> = .failure(TestError.generic)
    var colorResult: Result<ColorDetailResponse, Error> = .failure(TestError.generic)
    private(set) var lastPage: Int?
    private(set) var lastId: Int?

    func fetchColors(page: Int) -> AnyPublisher<ColorListResponse, Error> {
        lastPage = page
        return colorsResult.publisher.eraseToAnyPublisher()
    }

    func fetchColor(id: Int) -> AnyPublisher<ColorDetailResponse, Error> {
        lastId = id
        return colorResult.publisher.eraseToAnyPublisher()
    }
}
