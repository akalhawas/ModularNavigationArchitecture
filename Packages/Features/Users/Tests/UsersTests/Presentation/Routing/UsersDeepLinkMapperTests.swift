//
//  UsersDeepLinkMapperTests.swift
//  UsersTests
//

import XCTest
@testable import Users

/// Pins the exact deep link URL shape other features rely on to reach Users
/// (e.g. Colors' cross-feature navigation button). Since that dependency is
/// a raw string with no compile-time link back to this mapper, this test is
/// the thing that catches a silent break if the URL shape ever changes here.
final class UsersDeepLinkMapperTests: XCTestCase {

    private let mapper = UsersDeepLinkMapper()

    func testResolvesTheURLColorsDependsOnForCrossFeatureNavigation() {
        let url = URL(string: "com.ali.modularnavigationexample://users/details?id=1")!

        let destination = mapper.map(url: url) as? UsersDestination

        XCTAssertEqual(destination, .details(id: 1))
    }

    func testResolvesDetailsWithArbitraryId() {
        let url = URL(string: "com.ali.modularnavigationexample://users/details?id=42")!

        let destination = mapper.map(url: url) as? UsersDestination

        XCTAssertEqual(destination, .details(id: 42))
    }

    func testReturnsNilForAnUnrelatedHost() {
        let url = URL(string: "com.ali.modularnavigationexample://colors/details?id=1")!

        XCTAssertNil(mapper.map(url: url))
    }

    func testReturnsNilForAnUnrelatedPath() {
        let url = URL(string: "com.ali.modularnavigationexample://users/list")!

        XCTAssertNil(mapper.map(url: url))
    }
}
