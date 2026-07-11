//
//  DeepLinkRouterTests.swift
//  NavigationTests
//

import Testing
import Foundation
@testable import Navigation

struct DeepLinkRouterTests {

    @Test func resolvesUsingTheMapperThatMatchesTheURL() {
        let router = DeepLinkRouter(mappers: [
            StubMapper(host: "featureA", destination: DummyDestination.main),
            StubMapper(host: "featureB", destination: DummyDestination.detail(id: "1")),
        ])

        let resolved = router.resolve(url: URL(string: "myapp://featureB/path")!) as? DummyDestination
        #expect(resolved == .detail(id: "1"))
    }

    @Test func returnsNilWhenNoMapperMatches() {
        let router = DeepLinkRouter(mappers: [
            StubMapper(host: "featureA", destination: DummyDestination.main),
        ])

        let resolved = router.resolve(url: URL(string: "myapp://unknown/path")!)
        #expect(resolved == nil)
    }

    @Test func returnsNilWhenThereAreNoMappersAtAll() {
        let router = DeepLinkRouter(mappers: [])
        let resolved = router.resolve(url: URL(string: "myapp://featureA")!)
        #expect(resolved == nil)
    }

    @Test func earlierMapperWinsOverALaterMapperThatWouldAlsoMatch() {
        // Mappers are evaluated in array order; the first non-nil result wins.
        let router = DeepLinkRouter(mappers: [
            StubMapper(host: "shared", destination: DummyDestination.main),
            StubMapper(host: "shared", destination: DummyDestination.detail(id: "ignored")),
        ])

        let resolved = router.resolve(url: URL(string: "myapp://shared")!) as? DummyDestination
        #expect(resolved == .main)
    }

    @Test func skipsNonMatchingMappersBeforeFindingAMatch() {
        let router = DeepLinkRouter(mappers: [
            StubMapper(host: "featureA", destination: DummyDestination.main),
            StubMapper(host: "featureC", destination: DummyDestination.detail(id: "irrelevant")),
            StubMapper(host: "featureB", destination: DummyDestination.detail(id: "2")),
        ])

        let resolved = router.resolve(url: URL(string: "myapp://featureB")!) as? DummyDestination
        #expect(resolved == .detail(id: "2"))
    }
}
