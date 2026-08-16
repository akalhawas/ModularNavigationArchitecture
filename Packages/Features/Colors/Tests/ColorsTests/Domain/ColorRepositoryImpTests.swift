//
//  ColorRepositoryImpTests.swift
//  ColorsTests
//

import XCTest
import NetworkService
@testable import Colors

final class ColorRepositoryImpTests: XCTestCase {

    private static let mockColor = AppColor(
        id: 7,
        name: "Mock AppColor",
        year: 2026,
        color: "#98B2D1",
        pantoneValue: "15-4020"
    )

    private static let mockSupport = SupportInfo(url: "https://reqres.in/#support-heading", text: "Mock data")

    func testFetchColorsSuccessReturnsDecodedResponse() {
        // Arrange
        let network = MockNetworkService()
        let response = ColorListResponse(page: 1, perPage: 6, total: 1, totalPages: 1, data: [Self.mockColor], support: Self.mockSupport)
        network.result = .success(response)
        let sut = ColorRepositoryImp(networkService: network)

        // Act
        var received: ColorListResponse?
        _ = sut.fetchColors(page: 1).sink(receiveCompletion: { _ in }, receiveValue: { received = $0 })

        // Assert
        XCTAssertEqual(received?.data, [Self.mockColor])
    }

    func testFetchColorsRequestsListEndpointWithPage() {
        // Arrange
        let network = MockNetworkService()
        network.result = .success(
            ColorListResponse(page: 5, perPage: 6, total: 1, totalPages: 1, data: [Self.mockColor], support: Self.mockSupport)
        )
        let sut = ColorRepositoryImp(networkService: network)

        // Act
        _ = sut.fetchColors(page: 5).sink(receiveCompletion: { _ in }, receiveValue: { _ in })

        // Assert
        guard case .list(let page) = network.requestedEndpoints.first as? ColorEndpoint else {
            return XCTFail("Expected ColorEndpoint.list")
        }
        XCTAssertEqual(page, 5)
    }

    func testFetchColorsFailurePropagatesError() {
        // Arrange
        let network = MockNetworkService()
        network.result = .failure(TestError.network)
        let sut = ColorRepositoryImp(networkService: network)

        // Act
        var receivedError: TestError?
        _ = sut.fetchColors(page: 1).sink(receiveCompletion: { completion in
            if case .failure(let error) = completion {
                receivedError = error as? TestError
            }
        }, receiveValue: { _ in })

        // Assert
        XCTAssertEqual(receivedError, TestError.network)
    }

    func testFetchColorSuccessReturnsDecodedResponse() {
        // Arrange
        let network = MockNetworkService()
        network.result = .success(ColorDetailResponse(data: Self.mockColor, support: Self.mockSupport))
        let sut = ColorRepositoryImp(networkService: network)

        // Act
        var received: ColorDetailResponse?
        _ = sut.fetchColor(id: 7).sink(receiveCompletion: { _ in }, receiveValue: { received = $0 })

        // Assert
        XCTAssertEqual(received?.data, Self.mockColor)
    }

    func testFetchColorRequestsDetailEndpointWithId() {
        // Arrange
        let network = MockNetworkService()
        network.result = .success(ColorDetailResponse(data: Self.mockColor, support: Self.mockSupport))
        let sut = ColorRepositoryImp(networkService: network)

        // Act
        _ = sut.fetchColor(id: 9).sink(receiveCompletion: { _ in }, receiveValue: { _ in })

        // Assert
        guard case .detail(let id) = network.requestedEndpoints.first as? ColorEndpoint else {
            return XCTFail("Expected ColorEndpoint.detail")
        }
        XCTAssertEqual(id, 9)
    }

    func testFetchColorFailurePropagatesError() {
        // Arrange
        let network = MockNetworkService()
        network.result = .failure(TestError.network)
        let sut = ColorRepositoryImp(networkService: network)

        // Act
        var receivedError: TestError?
        _ = sut.fetchColor(id: 1).sink(receiveCompletion: { completion in
            if case .failure(let error) = completion {
                receivedError = error as? TestError
            }
        }, receiveValue: { _ in })

        // Assert
        XCTAssertEqual(receivedError, TestError.network)
    }
}
