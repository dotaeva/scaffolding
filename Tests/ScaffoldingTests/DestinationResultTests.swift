import Testing
import SwiftUI
import Observation
import ScaffoldingTesting
@testable import Scaffolding

@MainActor
@Suite("Destination results", .timeLimit(.minutes(1)))
struct DestinationResultTests {
    @Test func plainPushReturnsThroughDestination() async throws {
        let flow = HomeFlowCoordinator().activated()
        let waiter = Task { await flow.route(to: .settings, awaiting: String.self) }
        defer { waiter.cancel() }
        await waitUntil { flow.depth == 1 }

        try #require(flow.stack.destinations.last).dismiss(returning: "selected")

        #expect(await waiter.value == "selected")
        #expect(flow.depth == 0)
    }

    @Test(arguments: [false, true])
    func destinationReturnsFromModal(fullScreen: Bool) async throws {
        let flow = HomeFlowCoordinator().activated()
        let waiter = Task {
            await flow.present(.settings, as: fullScreen ? .fullScreenCover : .sheet, awaiting: Int.self)
        }
        defer { waiter.cancel() }
        await waitUntil { flow.isPresentingModal }

        try #require(flow.stack.destinations.last).dismiss(returning: 7)

        #expect(await waiter.value == 7)
        #expect(!flow.isPresentingModal)
    }

    enum Removal: CaseIterable {
        case pop, count, root, replaceRoot, replaceLast, nativeBack
    }

    @Test(arguments: Removal.allCases)
    func ordinaryRemovalReturnsNil(removal: Removal) async {
        let flow = HomeFlowCoordinator().activated()
        let waiter = Task { await flow.route(to: .settings, awaiting: String.self) }
        defer { waiter.cancel() }
        await waitUntil { flow.depth == 1 }

        switch removal {
        case .pop: flow.pop()
        case .count: flow.pop(1)
        case .root: flow.popToRoot()
        case .replaceRoot: flow.setRoot(.home)
        case .replaceLast: flow.replaceLast(with: .home)
        // This is the same binding SwiftUI writes on native back/dismiss.
        case .nativeBack: flow.bindingStack(for: .push).wrappedValue = []
        }

        #expect(await waiter.value == nil)
    }

    @Test func mismatchedResultReturnsNil() async throws {
        let flow = HomeFlowCoordinator().activated()
        let waiter = Task { await flow.route(to: .settings, awaiting: Int.self) }
        defer { waiter.cancel() }
        await waitUntil { flow.depth == 1 }
        try #require(flow.stack.destinations.last).dismiss(returning: "wrong type")
        #expect(await waiter.value == nil)
        #expect(flow.depth == 0)
    }

    @Test func distinctPushReturnsImmediately() async {
        let flow = HomeFlowCoordinator().activated()
        flow.route(to: .settings)
        let result = await flow.route(to: .settings, policy: .distinct, awaiting: String.self)
        #expect(result == nil)
        #expect(flow.depth == 1)
    }

    @Test func cancellationBeforePushDoesNotNavigate() async {
        let flow = HomeFlowCoordinator().activated()
        let waiter = Task { await flow.route(to: .settings, awaiting: String.self) }
        waiter.cancel()
        #expect(await waiter.value == nil)
        #expect(flow.depth == 0)
    }

    @Test func cancellationAfterPushLeavesScreenInPlace() async throws {
        let flow = HomeFlowCoordinator().activated()
        let waiter = Task { await flow.route(to: .settings, awaiting: String.self) }
        await waitUntil { flow.depth == 1 }
        waiter.cancel()
        #expect(await waiter.value == nil)
        #expect(flow.depth == 1)
        try #require(flow.stack.destinations.last).dismiss(returning: "late result")
        #expect(flow.depth == 0)
    }

    @Test func pushedChildCoordinatorReturnsToParent() async throws {
        let flow = HomeFlowCoordinator().activated()
        let waiter = Task { await flow.route(to: .detail, awaiting: Int.self) }
        defer { waiter.cancel() }
        await waitUntil { flow.depth == 1 }
        let child = try #require(flow.descendant(ofType: DetailFlowCoordinator.self))
        child.dismissCoordinator(returning: 42)
        #expect(await waiter.value == 42)
        #expect(flow.depth == 0)
        #expect(child.parent == nil)
    }

    @Test func repeatedCasesHaveIndependentResults() async throws {
        let flow = HomeFlowCoordinator().activated()
        let first = Task { await flow.route(to: .settings, awaiting: String.self) }
        defer { first.cancel() }
        await waitUntil { flow.depth == 1 }
        let second = Task { await flow.route(to: .settings, awaiting: String.self) }
        defer { second.cancel() }
        await waitUntil { flow.depth == 2 }

        try #require(flow.stack.destinations.last).dismiss(returning: "second")
        #expect(await second.value == "second")
        #expect(flow.depth == 1)
        try #require(flow.stack.destinations.last).dismiss(returning: "first")
        #expect(await first.value == "first")
    }

    @Test func destinationDismissesItsOwnRouteAndResolvesLaterRoutes() async throws {
        let flow = HomeFlowCoordinator().activated()
        let first = Task { await flow.route(to: .settings, awaiting: String.self) }
        defer { first.cancel() }
        await waitUntil { flow.depth == 1 }
        // Exercise the same value that the renderer supplies to \.destination.
        let destination = try #require(flow.stack.destinations.last)
        let second = Task { await flow.route(to: .settings, awaiting: String.self) }
        defer { second.cancel() }
        await waitUntil { flow.depth == 2 }

        destination.dismiss(returning: "first")

        #expect(await first.value == "first")
        #expect(await second.value == nil)
        #expect(flow.depth == 0)

        flow.route(to: .settings)
        destination.dismiss(returning: "stale")
        destination.dismiss()
        #expect(flow.depth == 1)
        #expect(await first.value == "first")
    }

    @Test func destinationPlainDismissReturnsNil() async throws {
        let flow = HomeFlowCoordinator().activated()
        let waiter = Task { await flow.route(to: .settings, awaiting: String.self) }
        defer { waiter.cancel() }
        await waitUntil { flow.depth == 1 }
        let destination = try #require(flow.stack.destinations.last)
        destination.dismiss()
        #expect(await waiter.value == nil)
        #expect(flow.depth == 0)
    }

    @Test(arguments: [0, 1, 2, 3], [false, true])
    func destinationReturnsFromViewOnlyModal(host: Int, fullScreen: Bool) async throws {
        let waiter: Task<String?, Never>
        let modal: () -> Destination?
        let isPresenting: () -> Bool
        let style: ModalPresentationType = fullScreen ? .fullScreenCover : .sheet
        switch host {
        case 0:
            let flow = ReviewFlow().activated()
            waiter = Task { await flow.present(.screen(id: 2), as: style, awaiting: String.self) }
            modal = { flow.stack.destinations.last }
            isPresenting = { flow.isPresentingModal }
        case 1:
            let root = ReviewRoot().activated()
            waiter = Task { await root.present(.other, as: style, awaiting: String.self) }
            modal = { root.root.modals.last }
            isPresenting = { root.isPresentingModal }
        case 2:
            let tabs = ReviewTabs().activated()
            waiter = Task { await tabs.present(.other, as: style, awaiting: String.self) }
            modal = { tabs.tabItems.modals.last }
            isPresenting = { tabs.isPresentingModal }
        default:
            let split = ReviewSplit().activated()
            waiter = Task { await split.present(.screen(id: 2), as: style, awaiting: String.self) }
            modal = { split.columns.modals.last }
            isPresenting = { split.isPresentingModal }
        }
        defer { waiter.cancel() }
        await waitUntil { isPresenting() }
        let destination = try #require(modal())
        destination.dismiss(returning: "selection")
        #expect(await waiter.value == "selection")
        #expect(!isPresenting())
    }

    @Test func rootDestinationReturnsThroughCoordinatorWrappers() async throws {
        let flow = ReviewFlow().activated()
        let waiter = Task { await flow.present(.wrapper, awaiting: String.self) }
        defer { waiter.cancel() }
        await waitUntil { flow.isPresentingModal }
        let wrapper = try #require(flow.descendant(ofType: ReviewRoot.self)).activated()
        let child = try #require(wrapper.descendant(ofType: ReviewFlow.self))
        let destination = try #require(child.stack.root)

        destination.dismiss(returning: "wrapped")

        #expect(await waiter.value == "wrapped")
        #expect(!flow.isPresentingModal)
        #expect(wrapper.parent == nil)
        flow.present(.screen(id: 2))
        destination.dismiss(returning: "stale")
        #expect(flow.isPresentingModal)
    }

    @Test func structuralDestinationsDoNotDismissUnrelatedRoutes() throws {
        let flow = HomeFlowCoordinator().activated()
        flow.dismissCoordinator(returning: "no parent")
        flow.route(to: .settings)
        try #require(flow.stack.root).dismiss(returning: "root")
        #expect(flow.depth == 1)

        let root = ReviewRoot().activated()
        root.setRoot(.other)
        root.present(.other)
        try #require(root.root.root).dismiss(returning: "root")
        #expect(root.isRoot(.other))
        #expect(root.isPresentingModal)

        let tabs = ReviewTabs().activated()
        tabs.present(.other)
        try #require(tabs.tabItems.tabs.last).dismiss(returning: "tab")
        #expect(tabs.isPresentingModal)

        let split = ReviewSplit().activated()
        split.present(.screen(id: 2))
        try #require(split.columns.sidebar).dismiss(returning: "column")
        #expect(split.isPresentingModal)
    }

    @Test func waitOnlyPresentationUsesAwaitingVoid() async {
        let flow = HomeFlowCoordinator().activated()
        var finished = false
        let waiter = Task {
            _ = await flow.present(.settings, awaiting: Void.self)
            finished = true
        }
        defer { waiter.cancel() }
        await waitUntil { flow.isPresentingModal }
        #expect(!finished)
        flow.dismissModal()
        await waiter.value
        #expect(finished)
    }

    @Test func optionalNilCanBeAnExplicitResult() async throws {
        let flow = HomeFlowCoordinator().activated()
        let waiter = Task { await flow.route(to: .settings, awaiting: String?.self) }
        defer { waiter.cancel() }
        await waitUntil { flow.depth == 1 }
        try #require(flow.stack.destinations.last).dismiss(returning: Optional<String>.none)
        switch await waiter.value {
        case .some(.none): break
        default: Issue.record("An explicit optional nil must remain distinct from dismissal without a result")
        }
    }

    @Test func reusedCoordinatorGetsANewRootDismissalLifetime() async throws {
        let host = ResultReuseHost().activated()
        let child = HomeFlowCoordinator().activated()
        host.present(.child(child))
        let staleRoot = try #require(child.stack.root)
        staleRoot.dismiss()
        #expect(!host.isPresentingModal)

        let waiter = Task { await host.present(.child(child), awaiting: String.self) }
        defer { waiter.cancel() }
        await waitUntil { host.isPresentingModal }
        staleRoot.dismiss(returning: "stale")
        #expect(host.isPresentingModal)
        try #require(child.stack.root).dismiss(returning: "current")
        #expect(await waiter.value == "current")
        #expect(!host.isPresentingModal)
    }
}

@MainActor @Observable @Scaffoldable
private final class ResultReuseHost: FlowCoordinatable {
    var stack = FlowStack<ResultReuseHost>(root: .home)
    func home() -> some View { EmptyView() }
    func child(_ coordinator: HomeFlowCoordinator) -> any Coordinatable { coordinator }
}
