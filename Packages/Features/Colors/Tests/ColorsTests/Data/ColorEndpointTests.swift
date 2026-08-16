//
//  ColorEndpointTests.swift
//  ColorsTests
//

import XCTest
import Foundation
@testable import Colors

final class ColorEndpointTests: XCTestCase {

    func testListPathIsColors() {
        // Arrange
        let sut = ColorEndpoint.list(page: 1)

        // Act
        let path = sut.path

        // Assert
        XCTAssertEqual(path, "/unknown")
    }

    func testListQueryItemsContainsPage() {
        // Arrange
        let sut = ColorEndpoint.list(page: 3)

        // Act
        let queryItems = sut.queryItems

        // Assert
        XCTAssertEqual(queryItems, [URLQueryItem(name: "page", value: "3")])
    }

    func testDetailPathIncludesId() {
        // Arrange
        let sut = ColorEndpoint.detail(id: 42)

        // Act
        let path = sut.path

        // Assert
        XCTAssertEqual(path, "/unknown/42")
    }

    func testDetailQueryItemsIsNil() {
        // Arrange
        let sut = ColorEndpoint.detail(id: 42)

        // Act
        let queryItems = sut.queryItems

        // Assert
        XCTAssertNil(queryItems)
    }

    func testMethodIsGet() {
        // Arrange
        let sut = ColorEndpoint.list(page: 1)

        // Act
        let method = sut.method

        // Assert
        XCTAssertEqual(method, .get)
    }

    func testHeadersContainAPIKey() {
        // Arrange
        let sut = ColorEndpoint.list(page: 1)

        // Act
        let headers = sut.headers

        // Assert
        XCTAssertEqual(headers?["x-api-key"], Secrets.reqresAPIKey)
    }
}
