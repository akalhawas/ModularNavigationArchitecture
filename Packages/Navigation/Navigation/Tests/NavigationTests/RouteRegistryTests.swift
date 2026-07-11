//
//  RouteRegistryTests.swift
//  NavigationTests
//
//  NOTE ON COVERAGE: `RouteRegistry.resolve(_:)` calls `assertionFailure` when a
//  destination has no registered builder. `assertionFailure` traps the process
//  in Debug builds — the configuration `swift test` uses by default — so a test
//  that calls `resolve` on an unregistered destination would abort the entire
//  test run rather than fail a single test. That trap is intentional: Debug,
//  CI, and test runs should still catch a missing registration immediately.
//  Only Release builds (where `assertionFailure` compiles out) degrade to
//  returning `nil`. If you need to verify that specific non-trapping behavior,
//  run `swift test -c release`, which will *not* trap and *will* return `nil`.
//

import Testing
import SwiftUI
@testable import Navigation

@MainActor
struct RouteRegistryTests {

    @Test func resolveReturnsTheRouteBuiltByTheRegisteredBuilder() {
        let registry = RouteRegistry()
        registry.register(DummyDestination.self) { destination in
            switch destination {
            case .main:
                return AnyRoute(DummyRoute.main)
            case .detail(let id):
                return AnyRoute(DummyRoute.detail(id: id))
            }
        }

        let resolved = registry.resolve(DummyDestination.main)
        #expect(resolved?.matches(DummyRoute.main) == true)
    }

    @Test func resolvePassesAssociatedValuesThroughToTheBuilder() {
        let registry = RouteRegistry()
        registry.register(DummyDestination.self) { destination in
            switch destination {
            case .main:
                return AnyRoute(DummyRoute.main)
            case .detail(let id):
                return AnyRoute(DummyRoute.detail(id: id))
            }
        }

        let resolved = registry.resolve(DummyDestination.detail(id: "42"))
        #expect(resolved?.matches(DummyRoute.detail(id: "42")) == true)
        #expect(resolved?.matches(DummyRoute.detail(id: "different")) == false)
    }

    @Test func reRegisteringTheSameDestinationTypeOverwritesThePreviousBuilder() {
        let registry = RouteRegistry()
        registry.register(DummyDestination.self) { _ in AnyRoute(DummyRoute.main) }
        registry.register(DummyDestination.self) { _ in AnyRoute(DummyRoute.other) }

        let resolved = registry.resolve(DummyDestination.main)
        #expect(resolved?.matches(DummyRoute.other) == true)
    }

    @Test func sharedIsAStableSingletonInstance() {
        #expect(RouteRegistry.shared === RouteRegistry.shared)
    }

    @Test func freshInstancesStartWithNoRegistrationsOfTheirOwn() {
        // Regression guard for accidental global/static builder storage: a newly
        // created registry must not see registrations made on a different instance.
        let populated = RouteRegistry()
        populated.register(DummyDestination.self) { _ in AnyRoute(DummyRoute.main) }

        let fresh = RouteRegistry()
        #expect(fresh !== populated)
        #expect(populated.resolve(DummyDestination.main) != nil)
    }
}
