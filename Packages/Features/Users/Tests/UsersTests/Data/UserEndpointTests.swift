//
//  UserEndpointTests.swift
//  UsersTests
//

import XCTest
import Foundation
@testable import Users

final class UserEndpointTests: XCTestCase {

    func testListPathIsUsers() {
        // Arrange
        let sut = UserEndpoint.list(page: 1)

        // Act
        let path = sut.path

        // Assert
        XCTAssertEqual(path, "/users")
    }

    func testListQueryItemsContainsPage() {
        // Arrange
        let sut = UserEndpoint.list(page: 3)

        // Act
        let queryItems = sut.queryItems

        // Assert
        XCTAssertEqual(queryItems, [URLQueryItem(name: "page", value: "3")])
    }

    func testDetailPathIncludesId() {
        // Arrange
        let sut = UserEndpoint.detail(id: 42)

        // Act
        let path = sut.path

        // Assert
        XCTAssertEqual(path, "/users/42")
    }

    func testDetailQueryItemsIsNil() {
        // Arrange
        let sut = UserEndpoint.detail(id: 42)

        // Act
        let queryItems = sut.queryItems

        // Assert
        XCTAssertNil(queryItems)
    }

    func testMethodIsGet() {
        // Arrange
        let sut = UserEndpoint.list(page: 1)

        // Act
        let method = sut.method

        // Assert
        XCTAssertEqual(method, .get)
    }

    func testHeadersContainAPIKey() {
        // Arrange
        let sut = UserEndpoint.list(page: 1)

        // Act
        let headers = sut.headers

        // Assert
        XCTAssertEqual(headers?["x-api-key"], Secrets.reqresAPIKey)
    }
}
