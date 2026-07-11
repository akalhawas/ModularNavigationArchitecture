//
//  URLQueryItemTests.swift
//  NavigationTests
//

import Testing
import Foundation
@testable import Navigation

struct URLQueryItemTests {

    @Test func returnsTheValueOfAnExistingQueryItem() {
        let url = URL(string: "myapp://featureB/subDetail?id=123")!
        #expect(url.queryItem("id") == "123")
    }

    @Test func returnsNilForAQueryItemThatIsNotPresent() {
        let url = URL(string: "myapp://featureB/subDetail?id=123")!
        #expect(url.queryItem("missing") == nil)
    }

    @Test func returnsNilWhenTheURLHasNoQueryItemsAtAll() {
        let url = URL(string: "myapp://featureB/subDetail")!
        #expect(url.queryItem("id") == nil)
    }

    @Test func returnsTheFirstValueWhenAKeyAppearsMoreThanOnce() {
        let url = URL(string: "myapp://x?id=1&id=2")!
        #expect(url.queryItem("id") == "1")
    }

    @Test func readsASpecificQueryItemAmongMultipleParameters() {
        let url = URL(string: "myapp://x?foo=bar&id=42&other=1")!
        #expect(url.queryItem("id") == "42")
        #expect(url.queryItem("foo") == "bar")
    }
}
