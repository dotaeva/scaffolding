//
//  AsyncNavigationTests.swift
//  ScaffoldingTests
//
//  Tests for routeAndWait/presentAndWait and the awaiting: result channel.
//

import Testing
import SwiftUI
@testable import Scaffolding

@MainActor
@Suite("Awaitable navigation")
struct AsyncNavigationTests {

    @Test("routeAndWait resumes when the destination is popped")
    func routeAndWaitResumesOnPop() async {
        let flow = HomeFlowCoordinator()
        _ = flow.anyStack

        let waiter = Task { await flow.routeAndWait(to: .settings) }
        while flow.anyStack.destinations.isEmpty { await Task.yield() }

        flow.pop()
        await waiter.value

        #expect(flow.anyStack.destinations.isEmpty)
    }

    @Test("routeAndWait resumes when the stack pops to root")
    func routeAndWaitResumesOnPopToRoot() async {
        let flow = HomeFlowCoordinator()
        _ = flow.anyStack
        flow.route(to: .settings)

        let waiter = Task { await flow.routeAndWait(to: .settings) }
        while flow.anyStack.destinations.count < 2 { await Task.yield() }

        flow.popToRoot()
        await waiter.value

        #expect(flow.anyStack.destinations.isEmpty)
    }

    @Test("routeAndWait with .distinct returns immediately when already on top")
    func routeAndWaitDistinctSkips() async {
        let flow = HomeFlowCoordinator()
        _ = flow.anyStack
        flow.route(to: .settings)

        await flow.routeAndWait(to: .settings, policy: .distinct)
        #expect(flow.anyStack.destinations.count == 1)
    }

    @Test("presentAndWait resumes when the modal is dismissed")
    func presentAndWaitResumesOnDismiss() async {
        let flow = HomeFlowCoordinator()
        _ = flow.anyStack

        let waiter = Task { await flow.presentAndWait(.sheetFlow) }
        while flow.anyStack.destinations.isEmpty { await Task.yield() }

        flow.dismissModal()
        await waiter.value

        #expect(flow.anyStack.destinations.isEmpty)
    }

    @Test("present(awaiting:) delivers the value from dismissCoordinator(returning:)")
    func awaitingResultDelivery() async {
        let flow = HomeFlowCoordinator()
        _ = flow.anyStack

        let waiter = Task { await flow.present(.sheetFlow, awaiting: String.self) }
        while flow.anyStack.destinations.isEmpty { await Task.yield() }

        let leaf = flow.anyStack.destinations.first?.coordinatable as? LeafFlowCoordinator
        leaf?.dismissCoordinator(returning: "token-123")

        let result = await waiter.value
        #expect(result == "token-123")
        #expect(flow.anyStack.destinations.isEmpty)
    }

    @Test("present(awaiting:) resumes with nil on a plain dismissal")
    func awaitingNilOnPlainDismiss() async {
        let flow = HomeFlowCoordinator()
        _ = flow.anyStack

        let waiter = Task { await flow.present(.sheetFlow, awaiting: String.self) }
        while flow.anyStack.destinations.isEmpty { await Task.yield() }

        flow.dismissModal()
        let result = await waiter.value
        #expect(result == nil)
    }

    @Test("present(awaiting:) resumes with nil on a result-type mismatch")
    func awaitingNilOnTypeMismatch() async {
        let flow = HomeFlowCoordinator()
        _ = flow.anyStack

        let waiter = Task { await flow.present(.sheetFlow, awaiting: Int.self) }
        while flow.anyStack.destinations.isEmpty { await Task.yield() }

        let leaf = flow.anyStack.destinations.first?.coordinatable as? LeafFlowCoordinator
        leaf?.dismissCoordinator(returning: "not an int")

        let result = await waiter.value
        #expect(result == nil)
    }

    @Test("presentAndWait on a RootCoordinatable resumes via dismissModal")
    func rootPresentAndWait() async {
        let app = AppRootCoordinator()
        _ = app.anyRoot

        let waiter = Task { await app.presentAndWait(.login) }
        while app.anyRoot.modals.isEmpty { await Task.yield() }

        app.dismissModal()
        await waiter.value
        #expect(app.anyRoot.modals.isEmpty)
    }

    @Test("present(awaiting:) on a TabCoordinatable delivers a result")
    func tabAwaitingResult() async {
        let tabs = MainTabCoordinator()
        _ = tabs.anyTabItems

        let waiter = Task { await tabs.present(.settings, awaiting: Int.self) }
        while tabs.anyTabItems.modals.isEmpty { await Task.yield() }

        let settings = tabs.anyTabItems.modals.first?.coordinatable as? SettingsFlowCoordinator
        settings?.dismissCoordinator(returning: 7)

        let result = await waiter.value
        #expect(result == 7)
        #expect(tabs.anyTabItems.modals.isEmpty)
    }

    @Test("onDismiss and the awaiting continuation both fire exactly once")
    func resolutionFiresOnce() async {
        let flow = HomeFlowCoordinator()
        _ = flow.anyStack
        var dismissCount = 0

        flow.present(.sheetFlow, onDismiss: { dismissCount += 1 })
        let destination = flow.anyStack.destinations.first

        flow.dismissModal()
        destination?.resolveDismissal() // second resolution must be a no-op

        #expect(dismissCount == 1)
    }
}
