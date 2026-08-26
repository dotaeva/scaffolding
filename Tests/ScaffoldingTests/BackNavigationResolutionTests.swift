//
//  BackNavigationResolutionTests.swift
//  ScaffoldingTests
//
//  A pushed destination can leave the stack two ways: programmatically
//  (pop/popToRoot/…), or because SwiftUI wrote a shorter path through the
//  NavigationStack binding — which is what a back button, a back swipe, and
//  an edge-swipe all do.
//
//  The programmatic paths are covered in AsyncNavigationTests. These cover
//  the binding, which is the one the *user* drives.
//

import Testing
import SwiftUI
@testable import Scaffolding

@MainActor
@Suite("Back-navigation resolution")
struct BackNavigationResolutionTests {

    /// Writes a new path through the same binding `NavigationStack(path:)`
    /// holds, standing in for a back button or a back swipe.
    private func popViaBackButton(
        _ flow: some FlowCoordinatable,
        to remaining: [Destination] = []
    ) {
        flow.bindingStack(for: .push).wrappedValue = remaining
    }

    @Test("onDismiss fires when the back button pops the destination")
    func onDismissFiresOnBackButton() {
        let flow = HomeFlowCoordinator()
        _ = flow.anyStack
        var dismissals = 0

        flow.route(to: .settings, onDismiss: { dismissals += 1 })
        #expect(flow.anyStack.destinations.count == 1)

        popViaBackButton(flow)

        #expect(flow.anyStack.destinations.isEmpty)
        #expect(dismissals == 1)
    }

    @Test("routeAndWait resumes when the back button pops the destination")
    func routeAndWaitResumesOnBackButton() async {
        let flow = HomeFlowCoordinator()
        _ = flow.anyStack

        let resumed = await finishesPromptly {
            let waiter = Task { await flow.routeAndWait(to: .settings) }
            while flow.anyStack.destinations.isEmpty { await Task.yield() }

            popViaBackButton(flow)
            await waiter.value
        }

        #expect(resumed, "routeAndWait never resumed after a back-button pop")
        #expect(flow.anyStack.destinations.isEmpty)
    }

    @Test("every destination the back gesture removes is resolved")
    func multiLevelPopResolvesAll() {
        let flow = HomeFlowCoordinator()
        _ = flow.anyStack
        var dismissals = 0

        flow.route(to: .settings, onDismiss: { dismissals += 1 })
        flow.route(to: .settings, onDismiss: { dismissals += 1 })
        flow.route(to: .settings, onDismiss: { dismissals += 1 })

        // A path written all the way back to the root — what popToRoot's
        // UI equivalent (a long-press on the back button) produces.
        popViaBackButton(flow)

        #expect(flow.anyStack.destinations.isEmpty)
        #expect(dismissals == 3)
    }

    @Test("a partial back navigation resolves only what it removed")
    func partialPopResolvesOnlyRemoved() {
        let flow = HomeFlowCoordinator()
        _ = flow.anyStack
        var dismissals = 0

        flow.route(to: .settings, onDismiss: { dismissals += 1 })
        flow.route(to: .settings, onDismiss: { dismissals += 1 })

        let kept = [flow.anyStack.destinations[0]]
        popViaBackButton(flow, to: kept)

        #expect(flow.anyStack.destinations.count == 1)
        #expect(dismissals == 1)
    }

    @Test("popping a child coordinator resolves what it had pushed")
    func droppedChildResolvesItsOwnStack() {
        let flow = HomeFlowCoordinator()
        _ = flow.anyStack
        var childDismissals = 0

        // A pushed child coordinator shares the parent's NavigationStack,
        // so its own pushes are part of the same path.
        flow.route(to: .detail)
        let child = flow.anyStack.destinations[0].coordinatable as? DetailFlowCoordinator
        #expect(child != nil)
        child?.route(to: .subDetail, onDismiss: { childDismissals += 1 })

        // Back all the way out: the child goes, and everything it pushed
        // goes with it.
        popViaBackButton(flow)

        #expect(flow.anyStack.destinations.isEmpty)
        #expect(childDismissals == 1)
    }

    @Test("a back-button pop after a programmatic pop does not double-resolve")
    func resolutionStaysSingleShot() {
        let flow = HomeFlowCoordinator()
        _ = flow.anyStack
        var dismissals = 0

        flow.route(to: .settings, onDismiss: { dismissals += 1 })
        flow.pop()

        // SwiftUI still writes the shorter path afterwards.
        popViaBackButton(flow)

        #expect(dismissals == 1)
    }
}

@MainActor
private final class CompletionFlag {
    var isSet = false
}

/// Runs `operation`, reporting whether it finished rather than hanging.
///
/// A regression in dismissal resolution leaves an awaiting continuation
/// suspended forever, which would wedge the whole suite instead of failing
/// one test. Resolution is synchronous, so a working implementation
/// completes within a handful of scheduler turns — hence yielding rather
/// than sleeping on the clock.
@MainActor
private func finishesPromptly(
    within turns: Int = 1_000,
    _ operation: @escaping @MainActor () async -> Void
) async -> Bool {
    let flag = CompletionFlag()
    let task = Task { @MainActor in
        await operation()
        flag.isSet = true
    }

    for _ in 0..<turns {
        if flag.isSet { return true }
        await Task.yield()
    }

    task.cancel()
    return false
}
