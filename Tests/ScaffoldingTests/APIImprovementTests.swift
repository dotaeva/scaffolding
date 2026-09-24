import SwiftUI
import Testing
import ScaffoldingTesting
@testable import Scaffolding

@MainActor @Observable @Scaffoldable(codable: true)
final class ReportingFlow: FlowCoordinatable {
    var stack = FlowStack<ReportingFlow>(root: .home)
    func home() -> some View { EmptyView() }
    func number(_ value: Double) -> some View { Text("\(value)") }
    func unsupported() -> any Coordinatable { RevalidationFlow() }
    @available(macOS 99, iOS 99, tvOS 99, watchOS 99, *)
    func future() -> some View { EmptyView() }
}

@MainActor @Suite("API improvements", .timeLimit(.minutes(1)))
struct APIImprovementTests {
    @Test func genericModalCapabilityDispatchesForEveryFamily() async throws {
        func check<C: Coordinatable>(_ owner: C, _ route: C.Destinations) async throws {
            let (child, result) = owner.present(route, expecting: ReviewFlow.self, awaiting: Int.self)
            #expect(owner.isPresentingModal)
            try #require(child).dismissCoordinator(returning: 42)
            #expect(await result() == 42)
            #expect(!owner.isPresentingModal)
        }
        try await check(ReviewFlow(), .child)
        try await check(ReviewRoot(), .child(id: 1))
        try await check(ReviewTabs(), .child(id: 1))
        try await check(ReviewSplit(), .child(id: 1))
    }

    @Test func selectedTabQueriesResolveInitialAndDynamicState() {
        let tabs = RevalidationTabs(RevalidationFlow())
        #expect(tabs.selectedTabIndex == 0)
        #expect(tabs.selectedTabDestination == .child)
        tabs.appendTab(.empty)
        tabs.select(index: 1)
        #expect(tabs.selectedTabDestination == .empty)
        tabs.removeFirstTab(.child)
        #expect(tabs.selectedTabIndex == 0)
        tabs.setTabs([])
        #expect(tabs.selectedTabIndex == nil)
        #expect(tabs.selectedTabDestination == nil)
    }

    @Test func modalQueuePreservesOrderAcrossStylesAndCancellation() {
        let flow = RevalidationFlow()
        flow.present(.screen(1), as: .fullScreenCover)
        flow.present(.screen(2), as: .sheet)
        let first = flow.presentationQueue[0].id
        #expect(flow.pendingModalCount == 1)
        flow.dismissModal() // Legacy latest-request behavior.
        #expect(flow.presentationQueue.first?.id == first)
        flow.present(.screen(3))
        flow.cancelPendingModals()
        #expect(flow.presentationQueue.map(\.id) == [first])
        flow.present(.screen(4))
        flow.dismissPresentedModal()
        #expect(flow.presentationQueue.count == 1)
        #expect(flow.presentationQueue.first?.id != first)
    }

    @Test func modalSelfDismissalPreservesQueuedSiblings() async throws {
        let flow = RevalidationFlow()
        let child = RevalidationFlow()
        let first = flow.present(.child(child), expecting: RevalidationFlow.self, awaiting: Int.self)
        flow.present(.screen(2))
        let queuedID = try #require(flow.stack.destinations.last).id
        child.dismissCoordinator(returning: 7)
        #expect(await first.result() == 7)
        #expect(flow.presentationQueue.map(\.id) == [queuedID])
        flow.present(.screen(3))
        try #require(flow.presentationQueue.first).dismiss()
        #expect(flow.presentationQueue.count == 1)
        #expect(flow.presentationQueue.first?.id != queuedID)
    }

    @Test func pendingCountsUseTheSharedFlowHost() {
        let child = RevalidationFlow()
        let flow = RevalidationFlow()
        flow.present(.screen(1))
        flow.route(to: .child(RevalidationRoot(child)))
        flow.activated()
        child.present(.screen(2))
        #expect(child.pendingModalCount == 1)
        child.cancelPendingModals()
        #expect(!child.isPresentingModal)
        #expect(flow.isPresentingModal)
    }

    @Test func reportingCaptureIdentifiesEncodingFailuresAndUnsupportedChildren() throws {
        let flow = ReportingFlow()
        flow.route(to: .number(.nan))
        #expect(throws: (any Error).self) { try flow.captureNavigationState() }
        let partial = try flow.captureNavigationStateWithReport()
        #expect(partial.report.capturedRoutes == 1)
        #expect(partial.report.skippedRoutes == 1)
        #expect(partial.report.issues.first?.path == ["entries[0]"])
        #expect(partial.report.issues.first?.reason == .encodingFailed)
        flow.popToRoot().route(to: .unsupported)
        let unsupported = try flow.captureNavigationStateWithReport()
        #expect(unsupported.report.issues.first?.reason == .unsupportedCoordinator)
        #expect(unsupported.report.issues.first?.path == ["entries[0]"])
    }

    @Test func restorationReportsSkippedRoutesAndDefaultsToReplace() throws {
        let flow = ReportingFlow()
        flow.route(to: .number(42))
        let node = try JSONDecoder().decode(NavigationStateNode.self, from: flow.captureNavigationState())
        node.entries.append(.init(route: Data("{}".utf8), presentation: .push))
        let restored = ReportingFlow()
        restored.route(to: .number(1))
        let report = try restored.restoreNavigationStateWithReport(from: JSONEncoder().encode(node))
        #expect(restored.depth == 1)
        #expect(report.restoredRoutes == 2)
        #expect(report.skippedRoutes == 1)
        #expect(report.issues.first?.path == ["entries[1]"])
    }

    @Test func migrationRunsBeforeMutationAndFutureSchemasFail() throws {
        enum MigrationError: Error { case stopped }
        let source = ReportingFlow()
        let data = try source.captureNavigationState(version: 7)
        let target = ReportingFlow()
        target.route(to: .number(9))
        #expect(throws: MigrationError.self) {
            try target.restoreNavigationStateWithReport(from: data) { _, version in
                #expect(version == 7)
                throw MigrationError.stopped
            }
        }
        #expect(target.depth == 1)
        let node = try JSONDecoder().decode(NavigationStateNode.self, from: data)
        node.schemaVersion = 99
        #expect(throws: NavigationStateError.self) {
            try target.restoreNavigationStateWithReport(from: JSONEncoder().encode(node))
        }
        #expect(target.depth == 1)
        _ = try target.restoreNavigationStateWithReport(from: JSONEncoder().encode(node)) { _, version in
            #expect(version == 7)
            node.schemaVersion = 1
            return try JSONEncoder().encode(node)
        }
        #expect(target.depth == 0)
    }

    @Test func unavailableDecodedRouteIsSkippedWithoutInvokingFactory() throws {
        let data = try ReportingFlow().captureNavigationState()
        let node = try JSONDecoder().decode(NavigationStateNode.self, from: data)
        node.entries = [.init(route: Data(#"{"future":{}}"#.utf8), presentation: .push)]
        let flow = ReportingFlow()
        let report = try flow.restoreNavigationStateWithReport(from: JSONEncoder().encode(node))
        #expect(flow.depth == 0)
        #expect(report.issues.first?.reason == .unavailableRoute)
    }

    @Test func deadlineWaitReturnsSuccessAndHonorsCancellation() async {
        #expect(await waitUntil({ true }, timeout: .zero))
        var ready = false
        let setter = Task { try? await Task.sleep(for: .milliseconds(10)); ready = true }
        #expect(await waitUntil({ ready }, timeout: .seconds(5)))
        await setter.value
        let waiting = Task { await waitUntil({ false }, timeout: .seconds(60)) }
        waiting.cancel()
        #expect(await waiting.value == false)
    }

    @Test func animationOverridesComposeAndRestoreAfterThrowing() throws {
        enum Stopped: Error { case stopped }
        let configured = Animation.linear(duration: 0.2)
        let override = Animation.easeIn(duration: 0.4)
        let flow = ReportingFlow()
        flow.setTransitionAnimation(configured)
        #expect(throws: Stopped.self) {
            try withNavigationTransaction(animation: .disabled) {
                let disabled = NavigationAnimationContext.transaction(default: configured)
                #expect(disabled.disablesAnimations && disabled.animation == nil)
                flow.route(to: .number(1))
                withNavigationTransaction(animation: .custom(override)) {
                    let custom = NavigationAnimationContext.transaction(default: configured)
                    #expect(!custom.disablesAnimations && custom.animation == override)
                    flow.route(to: .number(2))
                }
                #expect(NavigationAnimationContext.transaction(default: configured).disablesAnimations)
                throw Stopped.stopped
            }
        }
        #expect(flow.depth == 2)
        #expect(flow.stack.animation == configured)
        let restored = NavigationAnimationContext.transaction(default: configured)
        #expect(!restored.disablesAnimations && restored.animation == configured)
    }

    @Test func deadlineTimeoutReportsAndReturnsFailure() async {
        await withKnownIssue("An expired deadline records an issue at the caller") {
            let success = await waitUntil({ false }, timeout: .zero)
            #expect(!success)
        }
    }

}
