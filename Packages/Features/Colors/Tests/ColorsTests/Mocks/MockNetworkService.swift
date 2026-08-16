//
//  MockNetworkService.swift
//  ColorsTests
//

import Combine
import NetworkService

final class MockNetworkService: NetworkService {

    var result: Result<Any, Error> = .failure(TestError.generic)
    private(set) var requestedEndpoints: [Endpoint] = []

    func request<T: Decodable>(_ endpoint: Endpoint) -> AnyPublisher<T, Error> {
        requestedEndpoints.append(endpoint)

        switch result {
        case .success(let value):
            guard let typed = value as? T else {
                return Fail(error: TestError.generic).eraseToAnyPublisher()
            }
            return Just(typed).setFailureType(to: Error.self).eraseToAnyPublisher()
        case .failure(let error):
            return Fail(error: error).eraseToAnyPublisher()
        }
    }
}
