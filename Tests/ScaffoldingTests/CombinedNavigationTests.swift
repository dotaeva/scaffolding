import SwiftUI
import Testing
import ScaffoldingTesting
@testable import Scaffolding

@MainActor @Suite("Combined child access and result navigation", .timeLimit(.minutes(1)))
struct CombinedNavigationTests {
    enum Kind: CaseIterable {
        case push, flowModal, rootModal, tabModal, splitModal
    }

    @Test(arguments: Kind.allCases, [false, true])
    func childIsAvailableBeforeWaiting(kind: Kind, fullScreen: Bool) async throws {
        let host = Host(kind)
        let style: ModalPresentationType = fullScreen ? .fullScreenCover : .sheet
        let navigation = host.navigate(as: style, expecting: ReviewFlow.self, awaiting: String.self)
        let child = try #require(navigation.coordinator)
        #expect(child === host.destination?.coordinatable)
        #expect(child.parent === host.coordinator)
        #expect(host.destination?.routeType == (kind == .push ? .push : fullScreen ? .fullScreenCover : .sheet))
        child.route(to: .screen(id: 42))
        #expect(child.depth == 1)

        var started = false
        var finished = false
        let waiter = Task {
            started = true
            let value = await navigation.result()
            finished = true
            return value
        }
        defer { waiter.cancel() }
        await waitUntil { started }
        #expect(!finished)
        child.dismissCoordinator(returning: "chosen")

        #expect(await waiter.value == "chosen")
        #expect(host.destination == nil)
        #expect(child.parent == nil)
        #expect(child.depth == 0)
    }

    @Test(arguments: Kind.allCases)
    func resultCanArriveBeforeWaiting(kind: Kind) async throws {
        let host = Host(kind)
        let (child, result) = host.navigate(expecting: ReviewFlow.self, awaiting: String.self)
        try #require(child).dismissCoordinator(returning: "early")
        #expect(await result() == "early")
        #expect(await result() == "early")
    }

    @Test(arguments: Kind.allCases, [false, true])
    func absentOrMismatchedResultIsNil(kind: Kind, wrongType: Bool) async throws {
        let host = Host(kind)
        let (child, result) = host.navigate(expecting: ReviewFlow.self, awaiting: String.self)
        let coordinator = try #require(child)
        if wrongType {
            coordinator.dismissCoordinator(returning: 42)
        } else {
            coordinator.dismissCoordinator()
        }
        #expect(await result() == nil)
        #expect(host.destination == nil)
    }

    @Test(arguments: Kind.allCases, [false, true])
    func nilChildStillHasAResultChannel(kind: Kind, viewOnly: Bool) async throws {
        let host = Host(kind)
        let (child, result) = host.navigate(
            viewOnly: viewOnly, expecting: LeafFlowCoordinator.self, awaiting: Int.self
        )
        #expect(child == nil)
        try #require(host.destination).dismiss(returning: 42)
        #expect(await result() == 42)
    }

    @Test(arguments: Kind.allCases)
    func distinctSkipDoesNotAttachToExistingResult(kind: Kind) async throws {
        let host = Host(kind)
        let first = host.navigate(expecting: ReviewFlow.self, awaiting: String.self)
        let id = try #require(host.destination?.id)
        let skipped = host.navigate(policy: .distinct, expecting: ReviewFlow.self, awaiting: String.self)
        #expect(skipped.coordinator == nil)
        #expect(await skipped.result() == nil)
        #expect(host.destination?.id == id)
        try #require(first.coordinator).dismissCoordinator(returning: "original")
        #expect(await first.result() == "original")
        #expect(host.destination == nil)
    }

    @Test(arguments: Kind.allCases)
    func cancellationLeavesTheRouteAndOtherWaitersAlive(kind: Kind) async throws {
        let host = Host(kind)
        let navigation = host.navigate(expecting: ReviewFlow.self, awaiting: String.self)
        let child = try #require(navigation.coordinator)
        var started = false
        let cancelled = Task {
            started = true
            return await navigation.result()
        }
        let remaining = Task { await navigation.result() }
        defer { cancelled.cancel(); remaining.cancel() }
        await waitUntil { started }
        cancelled.cancel()
        #expect(await cancelled.value == nil)
        #expect(host.destination != nil)
        #expect(child.parent === host.coordinator)
        child.dismissCoordinator(returning: "remaining")
        #expect(await remaining.value == "remaining")
    }

    @Test(arguments: Kind.allCases)
    func cancelledCallerCreatesNoDestination(kind: Kind) async {
        let host = Host(kind)
        let caller = Task {
            let navigation = host.navigate(expecting: ReviewFlow.self, awaiting: String.self)
            #expect(navigation.coordinator == nil)
            #expect(await navigation.result() == nil)
        }
        caller.cancel()
        await caller.value
        #expect(host.destination == nil)
    }

    @Test(arguments: Kind.allCases)
    func supportsNonSendableResultsAndOptionalNil(kind: Kind) async throws {
        let host = Host(kind)
        let payload = Payload()
        let first = host.navigate(expecting: ReviewFlow.self, awaiting: Payload.self)
        try #require(first.coordinator).dismissCoordinator(returning: payload)
        #expect(await first.result() === payload)

        let second = host.navigate(expecting: ReviewFlow.self, awaiting: String?.self)
        try #require(second.coordinator).dismissCoordinator(returning: Optional<String>.none)
        switch await second.result() {
        case .some(.none): break
        default: Issue.record("An explicit nil result must differ from dismissal without a result")
        }
    }

    @Test func waitingClosureDoesNotRetainDismissedCoordinator() async throws {
        let host = Host(.push)
        weak var weakChild: ReviewFlow?
        let result: @MainActor () async -> Void?
        do {
            let navigation = host.navigate(expecting: ReviewFlow.self, awaiting: Void.self)
            let child = try #require(navigation.coordinator)
            weakChild = child
            result = navigation.result
            child.dismissCoordinator()
        }
        #expect(weakChild == nil)
        _ = await result()
    }

    private final class Payload {
        var value = "non-Sendable"
    }

    @MainActor
    private enum Host {
        case push(ReviewFlow), flow(ReviewFlow), root(ReviewRoot), tabs(ReviewTabs), split(ReviewSplit)

        init(_ kind: Kind) {
            switch kind {
            case .push: self = .push(ReviewFlow().activated())
            case .flowModal: self = .flow(ReviewFlow().activated())
            case .rootModal: self = .root(ReviewRoot().activated())
            case .tabModal: self = .tabs(ReviewTabs().activated())
            case .splitModal: self = .split(ReviewSplit().activated())
            }
        }

        var coordinator: any Coordinatable {
            switch self {
            case .push(let flow), .flow(let flow): flow
            case .root(let root): root
            case .tabs(let tabs): tabs
            case .split(let split): split
            }
        }

        var destination: Destination? {
            switch self {
            case .push(let flow), .flow(let flow): flow.stack.destinations.last
            case .root(let root): root.root.modals.last
            case .tabs(let tabs): tabs.tabItems.modals.last
            case .split(let split): split.columns.modals.last
            }
        }

        func navigate<T: Coordinatable, Result>(
            viewOnly: Bool = false,
            as style: ModalPresentationType = .sheet,
            policy: RoutePolicy = .always,
            expecting coordinatorType: T.Type,
            awaiting resultType: Result.Type
        ) -> (coordinator: T?, result: @MainActor () async -> Result?) {
            switch self {
            case .push(let flow):
                flow.route(to: viewOnly ? .screen(id: 2) : .child, policy: policy,
                           expecting: coordinatorType, awaiting: resultType)
            case .flow(let flow):
                flow.present(viewOnly ? .screen(id: 2) : .child, as: style, policy: policy,
                             expecting: coordinatorType, awaiting: resultType)
            case .root(let root):
                root.present(viewOnly ? .other : .child(id: 2), as: style, policy: policy,
                             expecting: coordinatorType, awaiting: resultType)
            case .tabs(let tabs):
                tabs.present(viewOnly ? .other : .child(id: 2), as: style, policy: policy,
                             expecting: coordinatorType, awaiting: resultType)
            case .split(let split):
                split.present(viewOnly ? .screen(id: 2) : .child(id: 2), as: style, policy: policy,
                              expecting: coordinatorType, awaiting: resultType)
            }
        }
    }
}
