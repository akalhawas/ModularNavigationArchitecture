//
//  MockFetchColorDetailUseCase.swift
//  ColorsTests
//

import Combine
@testable import Colors

final class MockFetchColorDetailUseCase: FetchColorDetailUseCase {

    var result: Result<ColorDetailResponse, Error> = .failure(TestError.generic)
    private(set) var executeCallCount = 0
    private(set) var lastId: Int?

    func execute(id: Int) -> AnyPublisher<ColorDetailResponse, Error> {
        executeCallCount += 1
        lastId = id
        return result.publisher.eraseToAnyPublisher()
    }
}
