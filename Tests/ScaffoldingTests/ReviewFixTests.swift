import SwiftUI
import Testing
import ScaffoldingTesting
@testable import Scaffolding

@MainActor @Observable @Scaffoldable(codable: true)
final class AvailabilityReviewFlow: FlowCoordinatable {
    var stack = FlowStack<AvailabilityReviewFlow>(root: .home)
    func home() -> some View { EmptyView() }
    @available(macOS 99, iOS 99, tvOS 99, watchOS 99, *)
    func future(id: Int) -> any Coordinatable { ReviewFlow() }
}

@MainActor @Observable @Scaffoldable(codable: true)
final class AvailabilityReviewRoot: RootCoordinatable {
    var root = Root<AvailabilityReviewRoot>(root: .home)
    func home() -> some View { EmptyView() }
    @available(macOS 99, iOS 99, tvOS 99, watchOS 99, *)
    func future(id: Int) -> any Coordinatable { ReviewFlow() }
}

@MainActor @Observable @Scaffoldable(codable: true)
final class AvailabilityReviewTabs: TabCoordinatable {
    var tabItems = TabItems<AvailabilityReviewTabs>(tabs: [.home])
    func home() -> some View { EmptyView() }
    @available(macOS 99, iOS 99, tvOS 99, watchOS 99, *)
    func future(id: Int) -> any Coordinatable { ReviewFlow() }
}

@MainActor @Observable @Scaffoldable(codable: true)
final class AvailabilityReviewSplit: SplitCoordinatable {
    var columns = SplitColumns<AvailabilityReviewSplit>(sidebar: .home, detail: .home)
    func home() -> some View { EmptyView() }
    @available(macOS 99, iOS 99, tvOS 99, watchOS 99, *)
    func future(id: Int) -> any Coordinatable { ReviewFlow() }
}

@MainActor @Observable @Scaffoldable
final class IdentityReviewFirst: FlowCoordinatable {
    let id = 42
    var stack = FlowStack<IdentityReviewFirst>(root: .home)
    func home() -> some View { EmptyView() }
}

@MainActor @Observable @Scaffoldable
final class IdentityReviewSecond: FlowCoordinatable {
    let id = 42
    var stack = FlowStack<IdentityReviewSecond>(root: .home)
    func home() -> some View { EmptyView() }
}

@MainActor @Observable @Scaffoldable
final class UnpersistedReviewFlow: FlowCoordinatable {
    var stack = FlowStack<UnpersistedReviewFlow>(root: .home, pushing: [.detail(id: 1)])
    func home() -> some View { EmptyView() }
    func detail(id: Int) -> some View { Text("\(id)") }
}

@MainActor @Observable @Scaffoldable(codable: true)
final class RestorationReviewFlow: FlowCoordinatable {
    var stack = FlowStack<RestorationReviewFlow>(root: .child)
    func child() -> any Coordinatable { UnpersistedReviewFlow() }
}

@MainActor @Observable @Scaffoldable(codable: true)
final class RestorationReviewRoot: RootCoordinatable {
    var root = Root<RestorationReviewRoot>(root: .child)
    func child() -> any Coordinatable { UnpersistedReviewFlow() }
}

@MainActor @Observable @Scaffoldable(codable: true)
final class RestorationReviewTabs: TabCoordinatable {
    var tabItems = TabItems<RestorationReviewTabs>(tabs: [.other, .child], selectedIndex: 1)
    func child() -> any Coordinatable { UnpersistedReviewFlow() }
    func other() -> any Coordinatable { ReviewFlow() }
}

@MainActor @Observable @Scaffoldable(codable: true)
final class RestorationReviewSplit: SplitCoordinatable {
    var columns = SplitColumns<RestorationReviewSplit>(sidebar: .other, content: .child, detail: .child)
    func child() -> any Coordinatable { UnpersistedReviewFlow() }
    func other() -> some View { EmptyView() }
}

@MainActor @Suite("Review fixes", .serialized, .timeLimit(.minutes(1)))
struct ReviewFixTests {
    private func unavailable<C: Coordinatable>(_ owner: C) throws -> C.Destinations where C.Destinations: Decodable {
        try JSONDecoder().decode(C.Destinations.self, from: Data(#"{"future":{"id":42}}"#.utf8))
    }

    @Test(arguments: [RoutePolicy.always, .distinct], [false, true])
    func allPresentationOverloadsSkipUnavailableRoutes(policy: RoutePolicy, cover: Bool) async throws {
        func check<C: Coordinatable>(_ owner: C) async throws where C.Destinations: Decodable {
            let route = try unavailable(owner)
            #expect(!route.isAvailable)
            let style: ModalPresentationType = cover ? .fullScreenCover : .sheet
            owner.present(route, as: style, policy: policy)
            #expect(!owner.isPresentingModal)
            #expect(owner.present(route, as: style, policy: policy, expecting: ReviewFlow.self) == nil)
            let combined = owner.present(route, as: style, policy: policy, expecting: ReviewFlow.self, awaiting: Int.self)
            #expect(combined.coordinator == nil)
            #expect(await combined.result() == nil)
            #expect(await owner.present(route, as: style, policy: policy, awaiting: Int.self) == nil)
            #expect(owner.pendingModalCount == 0)
        }
        try await check(AvailabilityReviewFlow())
        try await check(AvailabilityReviewRoot())
        try await check(AvailabilityReviewTabs())
        try await check(AvailabilityReviewSplit())
    }

    @Test func unavailableNavigationPreservesExistingBranches() async throws {
        let flow = AvailabilityReviewFlow().activated()
        let route = try unavailable(flow)
        let rootID = flow.stack.root?.id
        flow.route(to: route)
        #expect(flow.route(to: route, expecting: ReviewFlow.self) == nil)
        #expect(await flow.route(to: route, awaiting: Int.self) == nil)
        let combined = flow.route(to: route, expecting: ReviewFlow.self, awaiting: Int.self)
        #expect(combined.coordinator == nil)
        #expect(await combined.result() == nil)
        await flow.routeAndWait(to: route)
        flow.setRoot(route)
        #expect(flow.setRoot(route, expecting: ReviewFlow.self) == nil)
        #expect(flow.stack.root?.id == rootID)
        #expect(flow.depth == 0)

        let root = AvailabilityReviewRoot().activated()
        let rootRoute = try unavailable(root)
        let originalRoot = root.root.root?.id
        root.setRoot(rootRoute)
        #expect(root.setRoot(rootRoute, expecting: ReviewFlow.self) == nil)
        #expect(root.root.root?.id == originalRoot)

        let tabs = AvailabilityReviewTabs().activated()
        let tabRoute = try unavailable(tabs)
        let originalTabs = tabs.tabItems.tabs.map(\.id)
        tabs.appendTab(tabRoute).insertTab(tabRoute, at: 0).setTabs([tabRoute])
        #expect(tabs.appendTab(tabRoute, expecting: ReviewFlow.self) == nil)
        #expect(tabs.insertTab(tabRoute, at: 0, expecting: ReviewFlow.self) == nil)
        #expect(tabs.tabItems.tabs.map(\.id) == originalTabs)

        let split = AvailabilityReviewSplit().activated()
        let columnRoute = try unavailable(split)
        let originalDetail = split.columns.detail?.id
        split.setDetail(columnRoute).setSidebar(columnRoute).setContent(columnRoute)
        #expect(split.setDetail(columnRoute, expecting: ReviewFlow.self) == nil)
        #expect(split.columns.detail?.id == originalDetail)
        #expect(!split.columns.hasContentColumn)
    }

    @Test func equalPublicIDsDoNotShareOwnershipOrResults() async throws {
        let host = RevalidationFlow()
        let first = IdentityReviewFirst()
        let second = IdentityReviewSecond()
        let a = host.present(.child(first), expecting: IdentityReviewFirst.self, awaiting: Int.self)
        let b = host.present(.child(second), as: .fullScreenCover, expecting: IdentityReviewSecond.self, awaiting: Int.self)
        #expect(first.routeType == .sheet)
        #expect(second.routeType == .fullScreenCover)
        second.dismissCoordinator(returning: 7)
        #expect(await b.result() == 7)
        #expect(second.parent == nil)
        #expect(first.parent === host)
        host.dismissAllModals()
        #expect(await a.result() == nil)
    }

    @Test(arguments: ["flow", "root", "tabs", "split"], [NavigationRestorationMode.replace, .replay])
    func missingChildSnapshotsRespectRestorationMode(kind: String, mode: NavigationRestorationMode) async throws {
        let host: any Coordinatable = switch kind {
        case "flow": RestorationReviewFlow()
        case "root": RestorationReviewRoot()
        case "tabs": RestorationReviewTabs()
        default: RestorationReviewSplit()
        }
        host.activated()
        let snapshot = try host.captureNavigationStateWithReport()
        #expect(snapshot.report.issues.contains { $0.reason == .unsupportedCoordinator })
        let original = host.descendants(ofType: UnpersistedReviewFlow.self)
        #expect(!original.isEmpty)
        let unaffectedTab = (host as? RestorationReviewTabs)?.tabItems.tabs.first?.id
        var results: [@MainActor () async -> Int?] = []
        for child in original {
            #expect(child.depth == 1)
            child.route(to: .detail(id: 2))
            results.append(child.present(.detail(id: 3), expecting: ReviewFlow.self, awaiting: Int.self).result)
        }
        try host.restoreNavigationState(from: snapshot.data, mode: mode)
        host.activated()
        let restored = host.descendants(ofType: UnpersistedReviewFlow.self)
        #expect(restored.count == original.count)
        for (old, current) in zip(original, restored) {
            if mode == .replace {
                #expect(current !== old)
                #expect(current.depth == 1)
                #expect(!current.isPresentingModal)
                #expect(old.parent == nil)
                #expect(old.depth == 0)
            } else {
                #expect(current === old)
                #expect(current.depth == 2)
                #expect(current.isPresentingModal)
                current.dismissAllModals()
            }
        }
        for result in results { #expect(await result() == nil) }
        if let tabs = host as? RestorationReviewTabs {
            #expect(tabs.tabItems.tabs.first?.id == unaffectedTab)
            #expect(tabs.selectedTabIndex == 1)
        }
    }
}
