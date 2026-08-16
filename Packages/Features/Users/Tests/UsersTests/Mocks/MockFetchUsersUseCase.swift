//
//  MockFetchUsersUseCase.swift
//  UsersTests
//

import Combine
@testable import Users

final class MockFetchUsersUseCase: FetchUsersUseCase {

    var result: Result<UserListResponse, Error> = .failure(TestError.generic)
    private(set) var executeCallCount = 0
    private(set) var lastPage: Int?

    func execute(page: Int) -> AnyPublisher<UserListResponse, Error> {
        executeCallCount += 1
        lastPage = page
        return result.publisher.eraseToAnyPublisher()
    }
}
