//
//  ModalDismissalTests.swift
//  ScaffoldingTests
//
//  Tests for presenter-side modal dismissal on Root, Tab, and Flow
//  coordinators via dismissModal().
//

import Testing
import SwiftUI
@testable import Scaffolding

// MARK: - RootCoordinatable.dismissModal

@MainActor
@Suite("RootCoordinatable.dismissModal")
struct RootModalDismissalTests {

    @Test("dismissModal removes the presented modal and fires onDismiss once")
    func dismissPresentedModal() {
        let app = AppRootCoordinator()
        var dismissCount = 0

        app.present(.login, onDismiss: { dismissCount += 1 })
        #expect(app.anyRoot.modals.count == 1)

        app.dismissModal()
        #expect(app.anyRoot.modals.isEmpty)
        #expect(dismissCount == 1)
    }

    @Test("dismissModal without a presented modal is a no-op")
    func noopWithoutModals() {
        let app = AppRootCoordinator()

        app.dismissModal()
        #expect(app.anyRoot.modals.isEmpty)
    }

    @Test("dismissModal removes the most recently presented modal first")
    func dismissIsLastInFirstOut() {
        let app = AppRootCoordinator()
        var firstDismissed = false
        var secondDismissed = false

        app.present(.login, onDismiss: { firstDismissed = true })
        app.present(.main, onDismiss: { secondDismissed = true })
        #expect(app.anyRoot.modals.count == 2)

        app.dismissModal()
        #expect(app.anyRoot.modals.count == 1)
        #expect(secondDismissed)
        #expect(!firstDismissed)

        app.dismissModal()
        #expect(app.anyRoot.modals.isEmpty)
        #expect(firstDismissed)
    }

    @Test("onDismiss does not fire twice when the modal was already resolved")
    func dismissalResolvesOnce() {
        let app = AppRootCoordinator()
        var dismissCount = 0

        app.present(.login, onDismiss: { dismissCount += 1 })
        app.anyRoot.modals.last?.resolveDismissal()

        app.dismissModal()
        #expect(app.anyRoot.modals.isEmpty)
        #expect(dismissCount == 1)
    }
}

// MARK: - TabCoordinatable.dismissModal

@MainActor
@Suite("TabCoordinatable.dismissModal")
struct TabModalDismissalTests {

    @Test("dismissModal removes the presented modal and fires onDismiss once")
    func dismissPresentedModal() {
        let tabs = MainTabCoordinator()
        var dismissCount = 0

        tabs.present(.settings, as: .fullScreenCover, onDismiss: { dismissCount += 1 })
        #expect(tabs.anyTabItems.modals.count == 1)

        tabs.dismissModal()
        #expect(tabs.anyTabItems.modals.isEmpty)
        #expect(dismissCount == 1)
    }

    @Test("dismissModal without a presented modal is a no-op")
    func noopWithoutModals() {
        let tabs = MainTabCoordinator()

        tabs.dismissModal()
        #expect(tabs.anyTabItems.modals.isEmpty)
    }

    @Test("dismissModal leaves the tabs themselves untouched")
    func tabsUnaffected() {
        let tabs = MainTabCoordinator()
        _ = tabs.anyTabItems
        let tabCount = tabs.tabItems.tabs.count
        let selected = tabs.tabItems.selectedTab

        tabs.present(.settings)
        tabs.dismissModal()

        #expect(tabs.tabItems.tabs.count == tabCount)
        #expect(tabs.tabItems.selectedTab == selected)
    }
}

// MARK: - FlowCoordinatable.dismissModal

@MainActor
@Suite("FlowCoordinatable.dismissModal")
struct FlowModalDismissalTests {

    @Test("dismissModal removes the presented modal and fires onDismiss once")
    func dismissPresentedModal() {
        let flow = HomeFlowCoordinator()
        var dismissCount = 0

        flow.present(.sheetFlow, onDismiss: { dismissCount += 1 })
        #expect(flow.anyStack.destinations.count == 1)

        flow.dismissModal()
        #expect(flow.anyStack.destinations.isEmpty)
        #expect(dismissCount == 1)
    }

    @Test("dismissModal leaves pushed destinations in place")
    func pushesPreserved() {
        let flow = HomeFlowCoordinator()

        flow.route(to: .settings)
        flow.present(.sheetFlow)
        #expect(flow.anyStack.destinations.count == 2)

        flow.dismissModal()
        #expect(flow.anyStack.destinations.count == 1)
        #expect(flow.anyStack.destinations.first?.pushType == .push)
    }

    @Test("dismissModal without a modal is a no-op — it never pops a push")
    func noopWithoutModals() {
        let flow = HomeFlowCoordinator()
        flow.route(to: .settings)

        flow.dismissModal()
        #expect(flow.anyStack.destinations.count == 1)
    }

    @Test("dismissModal on an empty stack does not dismiss the coordinator")
    func noopOnEmptyStack() {
        let flow = HomeFlowCoordinator()
        _ = flow.anyStack

        flow.dismissModal()
        #expect(flow.anyStack.destinations.isEmpty)
        #expect(flow.anyStack.root != nil)
    }

    @Test("dismissModal removes the most recently presented modal first")
    func dismissIsLastInFirstOut() {
        let flow = HomeFlowCoordinator()
        var sheetDismissed = false
        var coverDismissed = false

        flow.present(.sheetFlow, as: .sheet, onDismiss: { sheetDismissed = true })
        flow.present(.detail, as: .fullScreenCover, onDismiss: { coverDismissed = true })

        flow.dismissModal()
        #expect(coverDismissed)
        #expect(!sheetDismissed)

        flow.dismissModal()
        #expect(sheetDismissed)
        #expect(flow.anyStack.destinations.isEmpty)
    }
}
