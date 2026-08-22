//
//  SplitCoordinatorTests.swift
//  ScaffoldingTests
//
//  Column navigation, modals, hierarchy introspection, macro integration,
//  and state restoration for SplitCoordinatable.
//

import Testing
import SwiftUI
import Observation
import ScaffoldingTesting
@testable import Scaffolding

// MARK: - Macro-based split coordinator

@MainActor @Observable @Scaffoldable(codable: true)
final class MacroSplitCoordinator: @MainActor SplitCoordinatable {
    var columns = SplitColumns<MacroSplitCoordinator>(
        sidebar: .sidebar,
        detail: .placeholder
    )

    func sidebar() -> some View { EmptyView() }
    func placeholder() -> some View { EmptyView() }
    func planetFlow() -> any Coordinatable { MacroCodableCoordinator() }

    // Void return type — never tracked by the macro.
    func selectPlanets() {
        setDetail(.planetFlow, policy: .distinct)
    }
}

// MARK: - Column navigation

@MainActor
@Suite("Split coordinator columns")
struct SplitColumnTests {

    @Test("activation resolves the initial columns")
    func activationResolvesColumns() {
        let split = LibrarySplitCoordinator().activated()

        #expect(split.sidebarDestination == .sidebar)
        #expect(split.detailDestination == .placeholder)
        #expect(split.contentDestination == nil)
        #expect(!split.anySplitColumns.hasContentColumn)
    }

    @Test("three-column container resolves the content column")
    func threeColumnResolvesContent() {
        let split = LibrarySplitCoordinator(threeColumn: true).activated()

        #expect(split.contentDestination == .list)
        #expect(split.anySplitColumns.hasContentColumn)
    }

    @Test("any column can host a child coordinator — including the sidebar")
    func sidebarCanBeCoordinator() {
        let split = LibrarySplitCoordinator().activated()

        let flow = split.setSidebar(.sidebarFlow, expecting: HomeFlowCoordinator.self)
        flow?.route(to: .settings)

        #expect(split.sidebarDestination == .sidebarFlow)
        #expect(flow?.parent === split)
        // The sidebar flow owns its own navigation layer inside the column.
        #expect(flow?.hasLayerNavigationCoordinatable == false)
        #expect(split.hierarchyContains(LibrarySplitCoordinator.self, .sidebarFlow, as: .column(.sidebar)))
        #expect(split.hierarchyContains(HomeFlowCoordinator.self, .settings, as: .push))
    }

    @Test("setDetail replaces the detail column")
    func setDetailReplaces() {
        let split = LibrarySplitCoordinator().activated()

        let flow = split.setDetail(.planet, expecting: DetailFlowCoordinator.self)

        #expect(flow != nil)
        #expect(split.detailDestination == .planet)
        #expect(split.isDetail(.planet))
        #expect(flow?.parent === split)
    }

    @Test("setDetail resolves initial columns on a cold coordinator")
    func setDetailWithoutActivation() {
        let split = LibrarySplitCoordinator()

        split.setDetail(.planet)

        #expect(split.detailDestination == .planet)
        #expect(split.sidebarDestination == .sidebar)
    }

    @Test(".distinct keeps the current detail and its state")
    func distinctPolicyKeepsDetail() {
        let split = LibrarySplitCoordinator().activated()

        let first = split.setDetail(.planet, expecting: DetailFlowCoordinator.self)
        first?.route(to: .subDetail)

        split.setDetail(.planet, policy: .distinct)

        let current = split.descendant(ofType: DetailFlowCoordinator.self)
        #expect(current === first)
        #expect(current?.depth == 1)
    }

    @Test(".always rebuilds the detail")
    func alwaysPolicyRebuildsDetail() {
        let split = LibrarySplitCoordinator().activated()

        let first = split.setDetail(.planet, expecting: DetailFlowCoordinator.self)
        let second = split.setDetail(.planet, expecting: DetailFlowCoordinator.self)

        #expect(first !== second)
    }

    @Test("setContent installs a content column on a two-column split")
    func setContentInstallsColumn() {
        let split = LibrarySplitCoordinator().activated()
        #expect(!split.anySplitColumns.hasContentColumn)

        split.setContent(.list)

        #expect(split.anySplitColumns.hasContentColumn)
        #expect(split.contentDestination == .list)
    }

    @Test("removeContent drops the content column")
    func removeContentDropsColumn() {
        let split = LibrarySplitCoordinator(threeColumn: true).activated()
        #expect(split.anySplitColumns.hasContentColumn)

        split.removeContent()

        #expect(!split.anySplitColumns.hasContentColumn)
        #expect(split.contentDestination == nil)

        // Idempotent: a second call is a safe no-op.
        split.removeContent()
        #expect(split.contentDestination == nil)
    }

    @Test("setContent works on a three-column split")
    func setContentOnThreeColumn() {
        let split = LibrarySplitCoordinator(threeColumn: true).activated()

        split.setContent(.placeholder)

        #expect(split.contentDestination == .placeholder)
    }

    @Test("setDetail typed closure fires with the resolved child")
    func typedClosureFires() {
        let split = LibrarySplitCoordinator().activated()
        var received: DetailFlowCoordinator?

        split.setDetail(.planet) { (flow: DetailFlowCoordinator) in
            received = flow
            flow.route(to: .subDetail)
        }

        #expect(received != nil)
        #expect(split.hierarchyContains(DetailFlowCoordinator.self, .subDetail, as: .push))
    }

    @Test("column visibility round-trips through the coordinator")
    func columnVisibility() {
        let split = LibrarySplitCoordinator().activated()

        split.setColumnVisibility(.detailOnly)

        #expect(split.columnVisibility == .detailOnly)
    }

    @Test("toggleSidebar flips between detailOnly and all")
    func toggleSidebar() {
        let split = LibrarySplitCoordinator().activated()
        #expect(split.isSidebarVisible)

        split.toggleSidebar()
        #expect(split.columnVisibility == .detailOnly)
        #expect(!split.isSidebarVisible)

        split.toggleSidebar()
        #expect(split.columnVisibility == .all)
        #expect(split.isSidebarVisible)
    }

    @Test("isSidebarVisible treats doubleColumn as hidden only with a content column")
    func sidebarVisibilityWithContentColumn() {
        let twoColumn = LibrarySplitCoordinator().activated()
        twoColumn.setColumnVisibility(.doubleColumn)
        #expect(twoColumn.isSidebarVisible)

        let threeColumn = LibrarySplitCoordinator(threeColumn: true).activated()
        threeColumn.setColumnVisibility(.doubleColumn)
        #expect(!threeColumn.isSidebarVisible)

        // toggleSidebar restores the sidebar from the doubleColumn state
        // instead of hiding everything.
        threeColumn.toggleSidebar()
        #expect(threeColumn.columnVisibility == .all)
        #expect(threeColumn.isSidebarVisible)
    }
}


// MARK: - Modals and dismissal

@MainActor
@Suite("Split coordinator modals")
struct SplitModalTests {

    @Test("present and presenter-side dismissal fire onDismiss once")
    func presentAndDismissModal() {
        let split = LibrarySplitCoordinator().activated()
        var dismissCount = 0

        split.present(.settings, onDismiss: { dismissCount += 1 })
        #expect(split.isPresentingModal)

        split.dismissModal()
        #expect(!split.isPresentingModal)
        #expect(dismissCount == 1)

        // No modal left — a second call is a safe no-op.
        split.dismissModal()
        #expect(dismissCount == 1)
    }

    @Test("a presented child dismisses itself with dismissCoordinator")
    func modalChildDismissesItself() {
        let split = LibrarySplitCoordinator().activated()

        let presented = split.present(.settings, expecting: LeafFlowCoordinator.self)
        #expect(split.isPresentingModal)

        presented?.dismissCoordinator()
        #expect(!split.isPresentingModal)
    }

    @Test("a column child cannot dismiss itself")
    func columnChildCannotDismiss() {
        let split = LibrarySplitCoordinator().activated()

        let flow = split.setDetail(.planet, expecting: DetailFlowCoordinator.self)
        flow?.dismissCoordinator()

        #expect(split.detailDestination == .planet)
        #expect(split.descendant(ofType: DetailFlowCoordinator.self) === flow)
    }

    @Test(".distinct skips presenting the same modal case twice")
    func distinctModalPolicy() {
        let split = LibrarySplitCoordinator().activated()

        split.present(.settings, policy: .distinct)
        split.present(.settings, policy: .distinct)

        #expect(split.anySplitColumns.modals.count == 1)
    }

    @Test("present(awaiting:) resumes with nil on presenter-side dismissal")
    func awaitingPresentationCancels() async {
        let split = LibrarySplitCoordinator().activated()

        let picking = Task { await split.present(.settings, awaiting: Int.self) }
        await waitUntil { split.isPresentingModal }

        split.dismissModal()

        #expect(await picking.value == nil)
    }

    @Test("present(awaiting:) delivers the returned value")
    func awaitingPresentationDelivers() async {
        let split = LibrarySplitCoordinator().activated()

        let picking = Task { await split.present(.settings, awaiting: Int.self) }
        await waitUntil { split.isPresentingModal }

        split.descendant(ofType: LeafFlowCoordinator.self)?.dismissCoordinator(returning: 42)

        #expect(await picking.value == 42)
        #expect(!split.isPresentingModal)
    }
}

// MARK: - Hierarchy and orientation

@MainActor
@Suite("Split coordinator hierarchy")
struct SplitHierarchyTests {

    @Test("columns appear in the snapshot with column roles")
    func snapshotRoles() {
        let split = LibrarySplitCoordinator().activated()
        split.setDetail(.planet)

        #expect(split.hierarchyContains(LibrarySplitCoordinator.self, .sidebar, as: .column(.sidebar)))
        #expect(split.hierarchyContains(LibrarySplitCoordinator.self, .planet, as: .column(.detail)))
        #expect(!split.hierarchyContains(LibrarySplitCoordinator.self, .planet, as: .column(.sidebar)))
    }

    @Test("debugHierarchy renders the split kind and column labels")
    func debugHierarchyOutput() {
        let split = LibrarySplitCoordinator().activated()
        split.setDetail(.planet)

        let output = split.debugHierarchy()

        #expect(output.contains("LibrarySplitCoordinator [split]"))
        #expect(output.contains("sidebar .sidebar"))
        #expect(output.contains("detail .planet → DetailFlowCoordinator [flow]"))
    }

    @Test("a column child reads .root routeType and reaches the split via ancestor")
    func columnChildOrientation() {
        let split = LibrarySplitCoordinator().activated()

        let flow = split.setDetail(.planet, expecting: DetailFlowCoordinator.self)

        #expect(flow?.routeType == .root)
        #expect(flow?.ancestor(ofType: LibrarySplitCoordinator.self) === split)
        #expect(flow?.hierarchyRoot === split)
    }

    @Test("a modal child reads .sheet routeType")
    func modalChildOrientation() {
        let split = LibrarySplitCoordinator().activated()

        let presented = split.present(.settings, expecting: LeafFlowCoordinator.self)

        #expect(presented?.routeType == .sheet)
    }

    @Test("column children never provide the parent's navigation layer")
    func columnChildOwnsItsNavigationLayer() {
        let split = LibrarySplitCoordinator().activated()

        let flow = split.setDetail(.planet, expecting: DetailFlowCoordinator.self)

        #expect(flow?.hasLayerNavigationCoordinatable == false)
    }
}

// MARK: - Macro integration and restoration

@MainActor
@Suite("Split coordinator macro and restoration")
struct SplitMacroTests {

    @Test("@Scaffoldable generates Destinations for a SplitCoordinatable")
    func macroGeneratesDestinations() {
        let split = MacroSplitCoordinator().activated()

        split.selectPlanets()

        #expect(split.detailDestination == .planetFlow)
        #expect(split.descendant(ofType: MacroCodableCoordinator.self) != nil)
    }

    @Test("navigation state round-trips columns, child state, and visibility")
    func restorationRoundTrip() throws {
        let split = MacroSplitCoordinator().activated()
        split.setColumnVisibility(.detailOnly)

        let flow = split.setDetail(.planetFlow, expecting: MacroCodableCoordinator.self)
        flow?.route(to: .detail(id: 7))

        let data = try split.captureNavigationState()

        let restored = MacroSplitCoordinator()
        try restored.restoreNavigationState(from: data)

        #expect(restored.detailDestination == .planetFlow)
        #expect(restored.columnVisibility == .detailOnly)

        let restoredFlow = restored.descendant(ofType: MacroCodableCoordinator.self)
        #expect(restoredFlow?.depth == 1)
        #expect(restoredFlow?.topDestination == .detail)
    }

    @Test("restoration is a no-op for matching column state")
    func restorationKeepsMatchingColumns() throws {
        let split = MacroSplitCoordinator().activated()
        let data = try split.captureNavigationState()

        let restored = MacroSplitCoordinator().activated()
        let before = restored.anySplitColumns.detail?.id
        try restored.restoreNavigationState(from: data)

        #expect(restored.anySplitColumns.detail?.id == before)
        #expect(restored.detailDestination == .placeholder)
    }
}
