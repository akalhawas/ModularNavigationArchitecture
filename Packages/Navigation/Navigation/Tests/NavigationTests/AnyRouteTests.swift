//
//  AnyRouteTests.swift
//  NavigationTests
//

import Testing
import SwiftUI
@testable import Navigation

@MainActor
struct AnyRouteTests {

    @Test func equalRoutesCompareEqual() {
        let a = AnyRoute(DummyRoute.main)
        let b = AnyRoute(DummyRoute.main)
        #expect(a == b)
    }

    @Test func differentCasesCompareUnequal() {
        let a = AnyRoute(DummyRoute.main)
        let b = AnyRoute(DummyRoute.other)
        #expect(a != b)
    }

    @Test func sameCaseWithDifferentAssociatedValuesComparesUnequal() {
        let a = AnyRoute(DummyRoute.detail(id: "1"))
        let b = AnyRoute(DummyRoute.detail(id: "2"))
        #expect(a != b)
    }

    @Test func sameCaseWithSameAssociatedValuesComparesEqual() {
        let a = AnyRoute(DummyRoute.detail(id: "42"))
        let b = AnyRoute(DummyRoute.detail(id: "42"))
        #expect(a == b)
    }

    @Test func matchesReturnsTrueForTheWrappedRoute() {
        let route = AnyRoute(DummyRoute.detail(id: "42"))
        #expect(route.matches(DummyRoute.detail(id: "42")))
    }

    @Test func matchesReturnsFalseForADifferentRoute() {
        let route = AnyRoute(DummyRoute.detail(id: "42"))
        #expect(!route.matches(DummyRoute.detail(id: "99")))
        #expect(!route.matches(DummyRoute.main))
    }

    @Test func eachWrapIsAnIndependentIdentityEvenWhenValueEqual() {
        // `id` backs SwiftUI's `Identifiable` presentation APIs (`.sheet(item:)`,
        // `.fullScreenCover(item:)`); it must stay unique per-wrap, independent of
        // `==`, or two equal-but-distinct pushes could collide in a `ForEach`/`sheet`.
        let a = AnyRoute(DummyRoute.main)
        let b = AnyRoute(DummyRoute.main)
        #expect(a.id != b.id)
        #expect(a == b)
    }

    @Test func capturesTheWrappedRoutesCustomSheetDetents() {
        let route = AnyRoute(CustomDetentRoute.screen)
        #expect(route.sheetDetents == [.medium])
    }

    @Test func fallsBackToTheProtocolDefaultSheetDetents() {
        let route = AnyRoute(DummyRoute.main)
        #expect(route.sheetDetents == [.large])
    }

    @Test func makeViewBuildsAViewWithoutCrashing() {
        let route = AnyRoute(DummyRoute.main)
        let coordinator = NavigationCoordinator()
        _ = route.makeView(coordinator: coordinator)
    }
}
