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
    private(set) var fetchColorsCallCount = 0
    private(set) var fetchColorCallCount = 0

    func fetchColors(page: Int) -> AnyPublisher<ColorListResponse, Error> {
        fetchColorsCallCount += 1
        lastPage = page
        return colorsResult.publisher.eraseToAnyPublisher()
    }

    func fetchColor(id: Int) -> AnyPublisher<ColorDetailResponse, Error> {
        fetchColorCallCount += 1
        lastId = id
        return colorResult.publisher.eraseToAnyPublisher()
    }
}
