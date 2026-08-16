//
//  MockFetchColorsUseCase.swift
//  ColorsTests
//

import Combine
@testable import Colors

final class MockFetchColorsUseCase: FetchColorsUseCase {

    var result: Result<ColorListResponse, Error> = .failure(TestError.generic)
    private(set) var executeCallCount = 0
    private(set) var lastPage: Int?

    func execute(page: Int) -> AnyPublisher<ColorListResponse, Error> {
        executeCallCount += 1
        lastPage = page
        return result.publisher.eraseToAnyPublisher()
    }
}
