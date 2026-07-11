//
//  NavigationCoordinatorTests.swift
//  NavigationTests
//

import Testing
import SwiftUI
@testable import Navigation

@MainActor
struct NavigationCoordinatorTests {

    // MARK: - Push

    @Test func navigatePushesOntoAnEmptyStack() {
        let coordinator = NavigationCoordinator()
        coordinator.navigate(to: DummyRoute.main)
        #expect(coordinator.routes.count == 1)
        #expect(coordinator.routes.first?.matches(DummyRoute.main) == true)
    }

    @Test func navigatePushesInCallOrder() {
        let coordinator = NavigationCoordinator()
        coordinator.navigate(to: DummyRoute.main)
        coordinator.navigate(to: DummyRoute.detail(id: "1"))
        #expect(coordinator.routes.count == 2)
        #expect(coordinator.routes[0].matches(DummyRoute.main))
        #expect(coordinator.routes[1].matches(DummyRoute.detail(id: "1")))
    }

    @Test func navigateDefaultsToPushStrategy() {
        let coordinator = NavigationCoordinator()
        coordinator.navigate(to: DummyRoute.main)
        coordinator.navigate(to: DummyRoute.other)
        #expect(coordinator.routes.count == 2)
    }

    @Test func navigateAcceptsAPreErasedAnyRoute() {
        let coordinator = NavigationCoordinator()
        coordinator.navigate(to: AnyRoute(DummyRoute.main))
        #expect(coordinator.routes.count == 1)
    }

    // MARK: - Reset stack

    @Test func resetStackReplacesAnExistingStackWithASingleRoute() {
        let coordinator = NavigationCoordinator()
        coordinator.navigate(to: DummyRoute.main)
        coordinator.navigate(to: DummyRoute.detail(id: "1"))
        coordinator.navigate(to: DummyRoute.other, strategy: .resetStack)
        #expect(coordinator.routes.count == 1)
        #expect(coordinator.routes.first?.matches(DummyRoute.other) == true)
    }

    @Test func resetStackOnAnEmptyStackPushesTheRoute() {
        let coordinator = NavigationCoordinator()
        coordinator.navigate(to: DummyRoute.main, strategy: .resetStack)
        #expect(coordinator.routes.count == 1)
    }

    // MARK: - popToIfExists

    @Test func popToIfExistsTrimsBackToAnExistingMatch() {
        let coordinator = NavigationCoordinator()
        coordinator.navigate(to: DummyRoute.main)
        coordinator.navigate(to: DummyRoute.detail(id: "1"))
        coordinator.navigate(to: DummyRoute.other)
        coordinator.navigate(to: DummyRoute.main, strategy: .popToIfExists)
        #expect(coordinator.routes.count == 1)
        #expect(coordinator.routes.first?.matches(DummyRoute.main) == true)
    }

    @Test func popToIfExistsKeepsEverythingUpToAndIncludingTheMatch() {
        let coordinator = NavigationCoordinator()
        coordinator.navigate(to: DummyRoute.main)
        coordinator.navigate(to: DummyRoute.detail(id: "1"))
        coordinator.navigate(to: DummyRoute.other)
        coordinator.navigate(to: DummyRoute.detail(id: "1"), strategy: .popToIfExists)
        #expect(coordinator.routes.count == 2)
        #expect(coordinator.routes.last?.matches(DummyRoute.detail(id: "1")) == true)
    }

    @Test func popToIfExistsPushesWhenTheRouteIsNotOnTheStack() {
        let coordinator = NavigationCoordinator()
        coordinator.navigate(to: DummyRoute.main)
        coordinator.navigate(to: DummyRoute.detail(id: "1"), strategy: .popToIfExists)
        #expect(coordinator.routes.count == 2)
        #expect(coordinator.routes.last?.matches(DummyRoute.detail(id: "1")) == true)
    }

    // MARK: - pop

    @Test func popRemovesTheTopRoute() {
        let coordinator = NavigationCoordinator()
        coordinator.navigate(to: DummyRoute.main)
        coordinator.navigate(to: DummyRoute.detail(id: "1"))
        coordinator.pop()
        #expect(coordinator.routes.count == 1)
        #expect(coordinator.routes.first?.matches(DummyRoute.main) == true)
    }

    @Test func popWithCountRemovesThatManyRoutes() {
        let coordinator = NavigationCoordinator()
        coordinator.navigate(to: DummyRoute.main)
        coordinator.navigate(to: DummyRoute.detail(id: "1"))
        coordinator.navigate(to: DummyRoute.other)
        coordinator.pop(count: 2)
        #expect(coordinator.routes.count == 1)
        #expect(coordinator.routes.first?.matches(DummyRoute.main) == true)
    }

    @Test func popClampsToTheStackSizeRatherThanTrapping() {
        let coordinator = NavigationCoordinator()
        coordinator.navigate(to: DummyRoute.main)
        coordinator.navigate(to: DummyRoute.detail(id: "1"))
        coordinator.pop(count: 99)
        #expect(coordinator.routes.isEmpty)
    }

    @Test func popOnAnEmptyStackIsANoOp() {
        let coordinator = NavigationCoordinator()
        coordinator.pop()
        #expect(coordinator.routes.isEmpty)
    }

    @Test func popWithZeroOrNegativeCountStillPopsExactlyOne() {
        let coordinator = NavigationCoordinator()
        coordinator.navigate(to: DummyRoute.main)
        coordinator.navigate(to: DummyRoute.detail(id: "1"))
        coordinator.pop(count: 0)
        #expect(coordinator.routes.count == 1)

        coordinator.navigate(to: DummyRoute.detail(id: "2"))
        coordinator.pop(count: -5)
        #expect(coordinator.routes.count == 1)
    }

    // MARK: - popTo(where:)

    @Test func popToWhereTrimsBackToTheLastMatch() {
        let coordinator = NavigationCoordinator()
        coordinator.navigate(to: DummyRoute.main)
        coordinator.navigate(to: DummyRoute.detail(id: "1"))
        coordinator.navigate(to: DummyRoute.other)
        coordinator.popTo { $0.matches(DummyRoute.main) }
        #expect(coordinator.routes.count == 1)
    }

    @Test func popToWhereMatchesTheLastOccurrenceOfADuplicatedRoute() {
        let coordinator = NavigationCoordinator()
        coordinator.navigate(to: DummyRoute.main)
        coordinator.navigate(to: DummyRoute.other)
        coordinator.navigate(to: DummyRoute.main)
        coordinator.popTo { $0.matches(DummyRoute.main) }
        // `popTo` uses `lastIndex(where:)`, so it should keep both `.main` entries
        // (index 0 and index 2), not trim back to the first occurrence.
        #expect(coordinator.routes.count == 3)
    }

    @Test func popToWhereIsANoOpWhenNothingMatches() {
        let coordinator = NavigationCoordinator()
        coordinator.navigate(to: DummyRoute.main)
        coordinator.navigate(to: DummyRoute.detail(id: "1"))
        coordinator.popTo { $0.matches(DummyRoute.other) }
        #expect(coordinator.routes.count == 2)
    }

    // MARK: - popToRoot

    @Test func popToRootClearsTheEntireStack() {
        let coordinator = NavigationCoordinator()
        coordinator.navigate(to: DummyRoute.main)
        coordinator.navigate(to: DummyRoute.detail(id: "1"))
        coordinator.popToRoot()
        #expect(coordinator.routes.isEmpty)
    }

    @Test func popToRootOnAnEmptyStackIsANoOp() {
        let coordinator = NavigationCoordinator()
        coordinator.popToRoot()
        #expect(coordinator.routes.isEmpty)
    }

    // MARK: - Sheet presentation

    @Test func presentSheetSetsTheSheetItem() {
        let coordinator = NavigationCoordinator()
        coordinator.presentSheet(DummyRoute.main)
        #expect(coordinator.sheetItem != nil)
        #expect(coordinator.sheetItem?.route.matches(DummyRoute.main) == true)
    }

    @Test func presentSheetDefaultsToTheRoutesOwnDetents() {
        let coordinator = NavigationCoordinator()
        coordinator.presentSheet(CustomDetentRoute.screen)
        #expect(coordinator.sheetItem?.configuration.detents == [.medium])
    }

    @Test func presentSheetExplicitDetentsOverrideTheRoutesDefault() {
        let coordinator = NavigationCoordinator()
        coordinator.presentSheet(DummyRoute.main, detents: [.height(200)])
        #expect(coordinator.sheetItem?.configuration.detents == [.height(200)])
    }

    @Test func presentingASecondSheetReplacesTheFirst() {
        let coordinator = NavigationCoordinator()
        coordinator.presentSheet(DummyRoute.main)
        coordinator.presentSheet(DummyRoute.other)
        #expect(coordinator.sheetItem?.route.matches(DummyRoute.other) == true)
    }

    @Test func dismissSheetClearsTheSheetItem() {
        let coordinator = NavigationCoordinator()
        coordinator.presentSheet(DummyRoute.main)
        coordinator.dismissSheet()
        #expect(coordinator.sheetItem == nil)
    }

    @Test func dismissSheetOnAnAlreadyDismissedSheetIsANoOp() {
        let coordinator = NavigationCoordinator()
        coordinator.dismissSheet()
        #expect(coordinator.sheetItem == nil)
    }

    // MARK: - Full-screen presentation

    @Test func presentFullScreenSetsTheFullScreenRoute() {
        let coordinator = NavigationCoordinator()
        coordinator.presentFullScreen(DummyRoute.main)
        #expect(coordinator.fullScreenRoute?.matches(DummyRoute.main) == true)
    }

    @Test func dismissFullScreenClearsTheFullScreenRoute() {
        let coordinator = NavigationCoordinator()
        coordinator.presentFullScreen(DummyRoute.main)
        coordinator.dismissFullScreen()
        #expect(coordinator.fullScreenRoute == nil)
    }

    // MARK: - Independence between instances

    @Test func eachCoordinatorOwnsItsOwnStateIndependently() {
        let a = NavigationCoordinator()
        let b = NavigationCoordinator()
        a.navigate(to: DummyRoute.main)
        #expect(a.routes.count == 1)
        #expect(b.routes.isEmpty)
    }
}
