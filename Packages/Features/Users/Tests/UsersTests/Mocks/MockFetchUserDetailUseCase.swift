//
//  MockFetchUserDetailUseCase.swift
//  UsersTests
//

import Combine
@testable import Users

final class MockFetchUserDetailUseCase: FetchUserDetailUseCase {

    var result: Result<UserDetailResponse, Error> = .failure(TestError.generic)
    private(set) var executeCallCount = 0
    private(set) var lastId: Int?

    func execute(id: Int) -> AnyPublisher<UserDetailResponse, Error> {
        executeCallCount += 1
        lastId = id
        return result.publisher.eraseToAnyPublisher()
    }
}
