import SwiftUI
import Observation
import Testing
import ScaffoldingTesting
@testable import Scaffolding

@MainActor @Observable @Scaffoldable(codable: true)
final class ReviewFlow: FlowCoordinatable {
    var stack = FlowStack<ReviewFlow>(root: .screen(id: 1))
    func screen(id: Int) -> some View { Text("\(id)") }
    func child() -> any Coordinatable { ReviewFlow() }
    func wrapper() -> any Coordinatable { ReviewRoot() }
    func tabs() -> any Coordinatable { ReviewTabs() }
    func split() -> any Coordinatable { ReviewSplit() }
}

@MainActor @Observable @Scaffoldable(codable: true)
final class ReviewRoot: RootCoordinatable {
    var root = Root<ReviewRoot>(root: .child(id: 1))
    func child(id: Int) -> any Coordinatable { ReviewFlow() }
    func other() -> some View { EmptyView() }
}

@MainActor @Observable @Scaffoldable(codable: true)
final class ReviewTabs: TabCoordinatable {
    var tabItems = TabItems<ReviewTabs>(tabs: [.child(id: 1), .other])
    func child(id: Int) -> any Coordinatable { ReviewFlow() }
    func other() -> some View { EmptyView() }
}

@MainActor @Observable @Scaffoldable(codable: true)
final class ReviewSplit: SplitCoordinatable {
    var columns = SplitColumns<ReviewSplit>(sidebar: .screen(id: 0), content: .screen(id: 1), detail: .child(id: 1))
    func child(id: Int) -> any Coordinatable { ReviewFlow() }
    func screen(id: Int) -> some View { Text("\(id)") }
}

@MainActor @Observable @Scaffoldable(injectsCoordinator: false)
final class ReviewOptOut: FlowCoordinatable {
    var stack = FlowStack<ReviewOptOut>(root: .screen)
    func screen() -> some View { EmptyView() }
}

@MainActor @Observable @Scaffoldable
final class ReviewFactoryTabs: TabCoordinatable {
    var tabItems = TabItems<ReviewFactoryTabs>(tabs: [.child])
    var calls = 0
    func child() -> (any Coordinatable, some View, TabRole) {
        calls += 1
        return (ReviewFlow(), Text("\(calls)"), .search)
    }
}

@MainActor @Suite("Review regressions", .serialized)
struct ReviewRegressionTests {
    enum Removal: CaseIterable {
        case pop, popCount, popToRoot, replace, setRoot, dismiss, back, dismissModal, dismissAll
    }

    @Test(arguments: Removal.allCases)
    func everyRemovalResolvesTheBranch(_ removal: Removal) throws {
        let parent = ReviewFlow()
        var callbacks: [String] = []
        let child: ReviewFlow
        let resolved: ReviewFlow?
        if removal == .dismissModal || removal == .dismissAll {
            resolved = parent.present(.child, onDismiss: { callbacks.append("owner") }, expecting: ReviewFlow.self)
        } else {
            resolved = parent.route(to: .child, onDismiss: { callbacks.append("owner") }, expecting: ReviewFlow.self)
        }
        child = try #require(resolved)
        child.route(to: .screen(id: 2), onDismiss: { callbacks.append("push") })
        child.present(.screen(id: 3), onDismiss: { callbacks.append("modal") })
        switch removal {
        case .pop: parent.pop()
        case .popCount: parent.pop(1)
        case .popToRoot: parent.popToRoot()
        case .replace: parent.replaceLast(with: .screen(id: 9))
        case .setRoot: parent.setRoot(.screen(id: 9))
        case .dismiss: child.dismissCoordinator()
        case .back: parent.bindingStack(for: .push).wrappedValue = []
        case .dismissModal: parent.dismissModal()
        case .dismissAll: parent.dismissAllModals()
        }
        #expect(callbacks == ["modal", "push", "owner"])
        #expect(child.parent == nil)
        #expect(child.depth == 0)
        #expect(!child.isPresentingModal)
    }

    @Test(arguments: ["wrapper", "tabs", "split"])
    func removalTraversesStructuralChildrenAndContainerModals(_ kind: String) throws {
        let route: ReviewFlow.Destinations = switch kind {
        case "wrapper": .wrapper
        case "tabs": .tabs
        default: .split
        }
        let parent = ReviewFlow()
        parent.route(to: route).activated()
        let branches = parent.descendants(ofType: ReviewFlow.self)
        #expect(!branches.isEmpty)
        var callbacks = 0
        for branch in branches {
            branch.route(to: .screen(id: 2), onDismiss: { callbacks += 1 })
        }
        let container = try #require(parent.anyStack.destinations.last?.coordinatable)
        if let root = container as? ReviewRoot {
            root.present(.other, onDismiss: { callbacks += 1 })
        } else if let tabs = container as? ReviewTabs {
            tabs.present(.other, onDismiss: { callbacks += 1 })
        } else if let split = container as? ReviewSplit {
            split.present(.screen(id: 3), onDismiss: { callbacks += 1 })
        }
        parent.pop()
        #expect(callbacks == branches.count + 1)
        #expect(branches.allSatisfy { $0.depth == 0 })
    }

    @Test func rootReplacementCallbackCanReplaceAgain() throws {
        let root = ReviewRoot()
        let child = try #require(root.anyRoot.root?.coordinatable as? ReviewFlow)
        child.route(to: .screen(id: 2), onDismiss: { root.setRoot(.child(id: 99)) })
        root.setRoot(.other)
        if case .child(let id) = root.anyRoot.root?.source as? ReviewRoot.Destinations {
            #expect(id == 99)
        } else { Issue.record("The callback's replacement was overwritten") }
    }

    @Test func retainedUnmaterializedDestinationDoesNotRetainOrCallItsOwner() {
        weak var owner: ReviewFlow?
        var destination: Destination?
        do {
            let flow = ReviewFlow()
            owner = flow
            destination = ReviewFlow.Destinations.child.value(for: flow)
        }
        #expect(owner == nil)
        #expect(destination?.coordinatable == nil)
    }

    @Test func snapshotOfColdCoordinatorDoesNotInitializeIt() {
        let root = ReviewRoot()
        #expect(root.hierarchySnapshot().isEmpty)
        _ = root.debugHierarchy()
        #expect(!root.root.isSetup)
    }

    @Test func removingDormantChildDoesNotInitializeIt() throws {
        let parent = ReviewFlow()
        let child = try #require(parent.route(to: .child, expecting: ReviewFlow.self))
        parent.pop()
        #expect(!child.stack.isSetup)
    }

    @Test func removedChildReleasesAndSnapshotDoesNotKeepOwnerAlive() throws {
        weak var owner: ReviewFlow?
        weak var removed: ReviewFlow?
        var snapshot: [HierarchyNode] = []
        do {
            let parent = ReviewFlow()
            owner = parent
            removed = parent.route(to: .child, expecting: ReviewFlow.self)
            #expect(removed != nil)
            snapshot = parent.hierarchySnapshot()
            parent.pop()
        }
        #expect(owner == nil)
        #expect(removed != nil) // A snapshot intentionally retains its child handle.
        snapshot.removeAll()
        #expect(removed == nil)
    }

    @Test func invalidTabRouteDoesNotRestoreIntoAnUnrelatedChild() throws {
        let tabs = ReviewTabs().activated()
        let child = try #require(tabs.selectFirstTab(.child, expecting: ReviewFlow.self))
        child.route(to: .screen(id: 42))
        let node = try JSONDecoder().decode(NavigationStateNode.self, from: tabs.captureNavigationState())
        node.tabRoutes?[0] = Data("{}".utf8)
        let restored = ReviewTabs().activated()
        try restored.restoreNavigationState(from: JSONEncoder().encode(node))
        #expect(restored.descendant(ofType: ReviewFlow.self)?.depth == 0)
    }

    @Test func olderSplitSnapshotKeepsDefaultContent() throws {
        let source = ReviewSplit()
        let node = try JSONDecoder().decode(NavigationStateNode.self, from: source.captureNavigationState())
        node.hasContentColumn = nil
        node.contentRoute = nil
        node.contentChild = nil
        let restored = ReviewSplit()
        try restored.restoreNavigationState(from: JSONEncoder().encode(node))
        #expect(restored.anySplitColumns.hasContentColumn)
    }

    @Test func replacementRestoreIsIdempotentAndPreservesCompactColumn() throws {
        let source = ReviewSplit()
        source.setPreferredCompactColumn(.detail)
        source.present(.screen(id: 2))
        let data = try source.captureNavigationState()
        let restored = ReviewSplit()
        try restored.restoreNavigationState(from: data, mode: .replace)
        try restored.restoreNavigationState(from: data, mode: .replace)
        #expect(restored.anySplitColumns.modals.count == 1)
        #expect(restored.anySplitColumns.preferredCompactColumn == .detail)
    }

    @Test func cancelledTaskDoesNotPresent() async {
        let parent = ReviewFlow()
        let task = Task { @MainActor in await parent.present(.child, awaiting: Int.self) }
        task.cancel()
        #expect(await task.value == nil)
        #expect(!parent.isPresentingModal)
    }

    @Test func structuralRootReturnsResultToTheActualPresenter() async throws {
        let parent = ReviewFlow()
        let task = Task { @MainActor in await parent.present(.wrapper, awaiting: Int.self) }
        await waitUntil { parent.isPresentingModal }
        let wrapper = try #require(parent.anyStack.destinations.last?.coordinatable as? ReviewRoot)
        let leaf = try #require(wrapper.anyRoot.root?.coordinatable as? ReviewFlow)
        leaf.dismissCoordinator(returning: 42)
        #expect(await task.value == 42)
        #expect(!parent.isPresentingModal)
    }

    @Test func tabRootCannotDismissItsStructuralOwner() throws {
        let tabs = ReviewTabs().activated()
        let flow = try #require(tabs.selectFirstTab(.child, expecting: ReviewFlow.self))
        flow.route(to: .screen(id: 2))
        flow.dismissCoordinator()
        #expect(flow.depth == 1)
        #expect(tabs.tabItems.tabs.count == 2)
    }

    @Test func presentationStyleSurvivesRootWrappersAndRootReplacement() throws {
        let presenter = ReviewFlow()
        let wrapper = try #require(presenter.present(.wrapper, expecting: ReviewRoot.self))
        #expect(!wrapper.root.isSetup)
        let original = try #require(wrapper.anyRoot.root?.coordinatable as? ReviewFlow)
        #expect(original.anyStack.root?.presentationType == .sheet)
        wrapper.setRoot(.child(id: 2))
        let replacement = try #require(wrapper.anyRoot.root?.coordinatable as? ReviewFlow)
        #expect(replacement.anyStack.root?.presentationType == .sheet)
    }

    @Test func inheritedStyleDoesNotInitializeStructuralContainers() {
        let root = ReviewRoot()
        let tabs = ReviewTabs()
        let split = ReviewSplit()
        root.setPresentedAs(.sheet)
        tabs.setPresentedAs(.sheet)
        split.setPresentedAs(.sheet)
        #expect(!root.root.isSetup)
        #expect(!tabs.tabItems.isSetup)
        #expect(!split.columns.isSetup)
        let child = tabs.anyTabItems.tabs.first?.coordinatable as? ReviewFlow
        #expect(child?.anyStack.root?.presentationType == .sheet)
    }

    @Test func optOutThroughExistential() {
        let flow = ReviewOptOut()
        #expect(flow._injectsCoordinator == false)
        #expect((flow as any Coordinatable)._injectsCoordinator == false)
    }

    @Test func activatedCoordinatorsRelease() {
        weak var weakFlow: ReviewFlow?
        weak var weakRoot: ReviewRoot?
        weak var weakTabs: ReviewTabs?
        weak var weakSplit: ReviewSplit?
        do { let c = ReviewFlow(); _ = c.view; weakFlow = c }
        do { let c = ReviewRoot(); _ = c.view; weakRoot = c }
        do { let c = ReviewTabs(); _ = c.view; weakTabs = c }
        do { let c = ReviewSplit(); _ = c.view; weakSplit = c }
        #expect(weakFlow == nil)
        #expect(weakRoot == nil)
        #expect(weakTabs == nil)
        #expect(weakSplit == nil)
    }

    @Test func programmaticPopResolvesChildWork() throws {
        let parent = ReviewFlow()
        let child = try #require(parent.route(to: .child, expecting: ReviewFlow.self))
        var dismissed = 0
        child.route(to: .screen(id: 2), onDismiss: { dismissed += 1 })
        parent.pop()
        #expect(dismissed == 1)
        #expect(child.depth == 0)
    }

    @Test func rootSwapResolvesChildWork() throws {
        let parent = ReviewRoot()
        let child = try #require(parent.anyRoot.root?.coordinatable as? ReviewFlow)
        var dismissed = 0
        child.route(to: .screen(id: 2), onDismiss: { dismissed += 1 })
        parent.setRoot(.other)
        #expect(dismissed == 1)
    }

    @Test func tabRemovalResolvesChildWork() throws {
        let parent = ReviewTabs()
        let child = try #require(parent.selectFirstTab(.child, expecting: ReviewFlow.self))
        var dismissed = 0
        child.route(to: .screen(id: 2), onDismiss: { dismissed += 1 })
        parent.removeFirstTab(.child)
        #expect(dismissed == 1)
    }

    @Test func columnReplacementResolvesChildWork() throws {
        let parent = ReviewSplit()
        let child = try #require(parent.anySplitColumns.detail?.coordinatable as? ReviewFlow)
        var dismissed = 0
        child.route(to: .screen(id: 2), onDismiss: { dismissed += 1 })
        parent.setDetail(.screen(id: 2))
        #expect(dismissed == 1)
    }

    @Test func dismissRootWrappedModalFromLeaf() throws {
        let parent = ReviewFlow()
        let wrapper = try #require(parent.present(.wrapper, expecting: ReviewRoot.self))
        let child = try #require(wrapper.anyRoot.root?.coordinatable as? ReviewFlow)
        child.dismissCoordinator()
        #expect(!parent.isPresentingModal)
    }

    @Test func popToLastFindsLastIncludingRootCase() {
        let flow = ReviewFlow()
        flow.route(to: .screen(id: 2))
        flow.route(to: .screen(id: 3))
        flow.route(to: .child)
        flow.popToLast(.screen)
        #expect(flow.depth == 2)
    }

    @Test func coldTabAppendSurvivesActivation() {
        let tabs = ReviewTabs()
        tabs.appendTab(.child(id: 2))
        _ = tabs.view
        #expect(tabs.anyTabItems.tabs.count == 3)
    }

    @Test func coldTabReplacementSurvivesActivation() {
        let tabs = ReviewTabs()
        tabs.setTabs([.other])
        _ = tabs.view
        #expect(tabs.anyTabItems.tabs.count == 1)
        #expect(tabs.anyTabItems.tabs.first?.meta as? ReviewTabs.Destinations.Meta == .other)
    }

    @Test func coldTabRemovalSurvivesActivation() {
        let tabs = ReviewTabs()
        tabs.removeFirstTab(.child)
        _ = tabs.view
        #expect(tabs.anyTabItems.tabs.count == 1)
    }

    @Test func setTabsSelectsAfterEmptyState() {
        let tabs = ReviewTabs()
        _ = tabs.view
        tabs.setTabs([])
        tabs.setTabs([.other])
        #expect(tabs.anyTabItems.selectedTab == tabs.anyTabItems.tabs.first?.id)
    }

    @Test func tabFactoryRunsOnce() {
        let tabs = ReviewFactoryTabs()
        _ = tabs.view
        _ = tabs.anyTabItems.tabs.first?.tabItem
        #expect(tabs.calls == 1)
    }

    @Test func restorationPreservesAssociatedValues() throws {
        let flow = ReviewFlow()
        flow.setRoot(.screen(id: 42))
        let restoredFlow = ReviewFlow()
        try restoredFlow.restoreNavigationState(from: flow.captureNavigationState())
        if case .screen(let id) = restoredFlow.anyStack.root?.source as? ReviewFlow.Destinations {
            #expect(id == 42)
        } else { Issue.record("Missing root route") }

        let root = ReviewRoot()
        root.setRoot(.child(id: 42))
        let restoredRoot = ReviewRoot()
        try restoredRoot.restoreNavigationState(from: root.captureNavigationState())
        if case .child(let id) = restoredRoot.anyRoot.root?.source as? ReviewRoot.Destinations {
            #expect(id == 42)
        } else { Issue.record("Missing root route") }

        let tabs = ReviewTabs()
        _ = tabs.view
        tabs.setTabs([.child(id: 42), .other])
        let restoredTabs = ReviewTabs()
        try restoredTabs.restoreNavigationState(from: tabs.captureNavigationState())
        if case .child(let id) = restoredTabs.anyTabItems.tabs.first?.source as? ReviewTabs.Destinations {
            #expect(id == 42)
        } else { Issue.record("Missing tab route") }

        let split = ReviewSplit()
        split.setDetail(.child(id: 42))
        let restoredSplit = ReviewSplit()
        try restoredSplit.restoreNavigationState(from: split.captureNavigationState())
        if case .child(let id) = restoredSplit.anySplitColumns.detail?.source as? ReviewSplit.Destinations {
            #expect(id == 42)
        } else { Issue.record("Missing column route") }
    }

    @Test func restorationRemovesContentColumn() throws {
        let split = ReviewSplit()
        split.removeContent()
        let restored = ReviewSplit()
        try restored.restoreNavigationState(from: split.captureNavigationState())
        #expect(!restored.anySplitColumns.hasContentColumn)
    }

    @Test func restorationDoesNotDuplicateSeededPath() throws {
        let flow = ReviewFlow()
        flow.stack = FlowStack(root: .screen(id: 1), pushing: [.screen(id: 2)])
        let restored = ReviewFlow()
        restored.stack = FlowStack(root: .screen(id: 1), pushing: [.screen(id: 2)])
        try restored.restoreNavigationState(from: flow.captureNavigationState(), mode: .replace)
        #expect(restored.depth == 1)
    }

    @Test func snapshotDoesNotMaterializeDescendants() throws {
        let parent = ReviewFlow()
        let child = try #require(parent.route(to: .child, expecting: ReviewFlow.self))
        #expect(child.stack.isSetup == false)
        _ = parent.hierarchySnapshot()
        #expect(child.stack.isSetup == false)
    }

    @Test func cancellationReleasesAwaiter() async throws {
        let flow = ReviewFlow()
        var completed = false
        let task = Task { @MainActor in
            await flow.presentAndWait(.child)
            completed = true
        }
        for _ in 0..<1000 { if flow.isPresentingModal { break }; await Task.yield() }
        #expect(flow.isPresentingModal)
        task.cancel()
        for _ in 0..<1000 { if completed { break }; await Task.yield() }
        #expect(completed)
        flow.dismissModal()
        await task.value
    }

    @Test func dismissalCallbackCanStartNextRoute() throws {
        let parent = ReviewFlow()
        let presented = parent.present(.child, onDismiss: {
            parent.route(to: .screen(id: 99))
        }, expecting: ReviewFlow.self)
        let child = try #require(presented)
        child.dismissCoordinator()
        #expect(parent.depth == 1)
    }

    @Test func coldNavigationRunsAfterSeededPath() {
        let flow = ReviewFlow()
        flow.stack = FlowStack(root: .screen(id: 1), pushing: [.screen(id: 2)])
        flow.route(to: .screen(id: 3))
        let ids = flow.anyStack.destinations.compactMap { destination -> Int? in
            if case .screen(let id) = destination.source as? ReviewFlow.Destinations { return id }
            return nil
        }
        #expect(ids == [2, 3])
    }

    @Test func sheetRootSeparatesRouteFromPresentation() throws {
        let parent = ReviewFlow()
        let child = try #require(parent.present(.child, expecting: ReviewFlow.self))
        #expect(child.routeType == .sheet)
        #expect(child.anyStack.root?.routeType == .root)
        #expect(child.anyStack.root?.presentationType == .sheet)
    }
}
