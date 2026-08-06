//
//  TestingSupportTests.swift
//  ScaffoldingTests
//
//  Tests for the ScaffoldingTesting product: activated(), descendant lookup,
//  typed hierarchy queries, waitUntil, and the public hierarchy snapshot the
//  first three are built on.
//

import Testing
import SwiftUI
import Scaffolding
import ScaffoldingTesting

// MARK: - activated()

@MainActor
@Suite("activated()")
struct ActivationTests {

    @Test("resolves a flow's root without rendering")
    func activatesFlow() {
        let flow = HomeFlowCoordinator().activated()

        #expect(flow.topDestination == .home)
        #expect(flow.anyStack.root != nil)
    }

    @Test("resolves a root coordinator's root")
    func activatesRoot() {
        let app = AppRootCoordinator().activated()

        #expect(app.isRoot(.main))
    }

    @Test("resolves a tab coordinator's tabs")
    func activatesTabs() {
        let tabs = MainTabCoordinator().activated()

        #expect(tabs.isInTabItems(.home))
        #expect(tabs.tabItems.selectedTab != nil)
    }

    @Test("is idempotent and returns the same instance")
    func idempotent() {
        let flow = HomeFlowCoordinator()
        flow.activated().route(to: .settings)

        #expect(flow.activated() === flow)
        #expect(flow.depth == 1)   // setup did not run twice and reset state
    }
}

// MARK: - Snapshot

@MainActor
@Suite("hierarchySnapshot()")
struct HierarchySnapshotTests {

    @Test("mirrors roles, metas, and nesting")
    func snapshotShape() {
        let app = AppRootCoordinator().activated()
        let tabs = app.descendant(ofType: MainTabCoordinator.self)
        let home = tabs?.descendant(ofType: HomeFlowCoordinator.self)
        home?.route(to: .settings)
        home?.present(.sheetFlow)

        let nodes = app.hierarchySnapshot()

        #expect(nodes.count == 1)
        #expect(nodes[0].role == .root)
        #expect(nodes[0].coordinator === tabs)

        let tabNodes = nodes[0].children
        #expect(tabNodes[0].role == .tab(index: 0, isSelected: true))
        #expect(tabNodes[1].role == .tab(index: 1, isSelected: false))

        let homeNodes = tabNodes[0].children
        #expect(homeNodes.map(\.role) == [.root, .push, .sheet])
        #expect(homeNodes[1].metaDescription == ".settings")
        #expect(homeNodes[2].role.isModal)
    }

    @Test("inspecting the tree twice changes nothing")
    func inspectionHasNoSideEffects() {
        let tabs = MainTabCoordinator().activated()

        let first = tabs.debugHierarchy()
        _ = tabs.hierarchySnapshot()
        let second = tabs.debugHierarchy()

        #expect(first == second)
        // Tab children are resolved by TabItems.setup, so they are already
        // created here; a node reports `hasCoordinator` either way and only
        // fills in `coordinator` once one exists.
        let allTabsBacked = tabs.hierarchySnapshot().allSatisfy { $0.hasCoordinator }
        #expect(allTabsBacked)
    }

    @Test("view-only destinations report no coordinator")
    func viewOnlyDestination() {
        let flow = HomeFlowCoordinator().activated()
        flow.route(to: .settings)

        let pushed = flow.hierarchySnapshot()[1]

        #expect(!pushed.hasCoordinator)
        #expect(pushed.coordinator == nil)
    }

    @Test("debugHierarchy renders the same tree it snapshots")
    func renderingMatchesSnapshot() {
        let app = AppRootCoordinator().activated()
        app.descendant(ofType: HomeFlowCoordinator.self)?.route(to: .settings)

        let dump = app.debugHierarchy()

        #expect(dump.hasPrefix("AppRootCoordinator [root]"))
        #expect(dump.contains("root .main → MainTabCoordinator [tab]"))
        #expect(dump.contains("tab[0]* .home → HomeFlowCoordinator [flow]"))
        #expect(dump.contains("push .settings"))
        #expect(dump.contains("tab[1] .profile → ProfileFlowCoordinator [flow]"))
    }
}

// MARK: - Descendant lookup

@MainActor
@Suite("descendant(ofType:)")
struct DescendantTests {

    @Test("finds a child created by the code under test")
    func findsPresentedChild() {
        let flow = HomeFlowCoordinator().activated()
        flow.present(.sheetFlow)   // no handle returned

        let sheet = flow.descendant(ofType: LeafFlowCoordinator.self)

        #expect(sheet != nil)
        #expect(sheet?.routeType == .sheet)
        #expect(sheet?.ancestor(ofType: HomeFlowCoordinator.self) === flow)
    }

    @Test("walks the whole tree, in tree order")
    func findsAcrossLevels() {
        let app = AppRootCoordinator().activated()
        let home = app.descendant(ofType: HomeFlowCoordinator.self)
        home?.present(.sheetFlow)
        home?.route(to: .detail)

        #expect(app.descendant(ofType: MainTabCoordinator.self) != nil)
        #expect(app.descendant(ofType: DetailFlowCoordinator.self) != nil)
        // The sheet was presented before the push, so it comes first.
        #expect(app.descendants(ofType: LeafFlowCoordinator.self).count == 1)
    }

    @Test("returns nil for a coordinator that was never created")
    func missingChild() {
        let flow = HomeFlowCoordinator().activated()

        #expect(flow.descendant(ofType: LeafFlowCoordinator.self) == nil)
        #expect(flow.descendants(ofType: DetailFlowCoordinator.self).isEmpty)
    }
}

// MARK: - Typed hierarchy queries

@MainActor
@Suite("hierarchyContains")
struct HierarchyContainsTests {

    @Test("matches a destination anywhere in the tree")
    func matchesAnyRole() {
        let app = AppRootCoordinator().activated()
        app.descendant(ofType: HomeFlowCoordinator.self)?.route(to: .settings)

        #expect(app.hierarchyContains(HomeFlowCoordinator.self, .settings))
        #expect(app.hierarchyContains(AppRootCoordinator.self, .main))
        #expect(!app.hierarchyContains(HomeFlowCoordinator.self, .detail))
    }

    @Test("optionally requires a role")
    func matchesRole() {
        let flow = HomeFlowCoordinator().activated()
        flow.route(to: .settings)
        flow.present(.sheetFlow)

        #expect(flow.hierarchyContains(HomeFlowCoordinator.self, .settings, as: .push))
        #expect(!flow.hierarchyContains(HomeFlowCoordinator.self, .settings, as: .sheet))
        #expect(flow.hierarchyContains(HomeFlowCoordinator.self, .sheetFlow, as: .sheet))
        #expect(flow.hierarchyContains(HomeFlowCoordinator.self, .home, as: .root))
    }

    @Test("matches tabs by index and selection")
    func matchesTabRole() {
        let tabs = MainTabCoordinator().activated()

        #expect(tabs.hierarchyContains(MainTabCoordinator.self, .home, as: .tab(index: 0, isSelected: true)))
        #expect(tabs.hierarchyContains(MainTabCoordinator.self, .profile, as: .tab(index: 1, isSelected: false)))
        #expect(!tabs.hierarchyContains(MainTabCoordinator.self, .home, as: .tab(index: 1, isSelected: false)))
    }
}

// MARK: - waitUntil

@MainActor
@Suite("waitUntil")
struct WaitUntilTests {

    @Test("returns as soon as the condition holds")
    func resolvesAwaitedPresentation() async {
        let flow = HomeFlowCoordinator().activated()

        let waiting = Task { await flow.presentAndWait(.sheetFlow) }
        await waitUntil { flow.isPresentingModal }

        // The child exists even though presentAndWait handed nothing back.
        #expect(flow.descendant(ofType: LeafFlowCoordinator.self) != nil)

        flow.dismissModal()
        await waiting.value

        #expect(!flow.isPresentingModal)
    }

    @Test("a result travels back from a coordinator found in the tree")
    func awaitedResult() async {
        let flow = HomeFlowCoordinator().activated()

        let picking = Task { await flow.present(.sheetFlow, awaiting: Int.self) }
        await waitUntil { flow.isPresentingModal }

        flow.descendant(ofType: LeafFlowCoordinator.self)?.dismissCoordinator(returning: 42)

        #expect(await picking.value == 42)
    }

    @Test("returns immediately when the condition already holds")
    func immediate() async {
        let flow = HomeFlowCoordinator().activated()

        await waitUntil { flow.topDestination == .home }

        #expect(flow.depth == 0)
    }
}
