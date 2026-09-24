import SwiftUI
import Testing
import ScaffoldingTesting
@testable import Scaffolding

@MainActor @Observable @Scaffoldable
final class RevalidationFlow: FlowCoordinatable {
    var stack: FlowStack<RevalidationFlow>
    init(root child: (any Coordinatable)? = nil) {
        stack = FlowStack(root: child.map { .child($0) } ?? .screen(0))
    }
    func screen(_ id: Int) -> some View { Text("\(id)") }
    func child(_ value: any Coordinatable) -> any Coordinatable { value }
}

@MainActor @Observable @Scaffoldable
final class RevalidationRoot: RootCoordinatable {
    var root: Root<RevalidationRoot>
    init(_ value: any Coordinatable) { root = Root(root: .child(value)) }
    func child(_ value: any Coordinatable) -> any Coordinatable { value }
    func empty() -> some View { EmptyView() }
}

@MainActor @Observable @Scaffoldable
final class RevalidationTabs: TabCoordinatable {
    var tabItems: TabItems<RevalidationTabs>
    init(_ value: any Coordinatable) { tabItems = TabItems(tabs: [.child(value)]) }
    func child(_ value: any Coordinatable) -> (any Coordinatable, some View) { (value, Text("Tab")) }
    func empty() -> some View { EmptyView() }
}

@MainActor @Suite("Navigation reattachment regressions", .serialized)
struct RevalidationProbeTests {
    @Test func coldRootWrapperRoutesCorrectly() {
        let leaf = RevalidationFlow()
        let wrapper = RevalidationRoot(leaf)
        let outer = RevalidationFlow()
        outer.route(to: .child(wrapper))
        outer.activated()
        leaf.route(to: .screen(1))
        #expect(leaf.hasLayerNavigationCoordinatable)
        #expect(outer.bindingStack(for: .push).wrappedValue.count == 2)
    }

    @Test func directFlowTabRoutesCorrectly() {
        let leaf = RevalidationFlow()
        let tabs = RevalidationTabs(leaf)
        let outer = RevalidationFlow()
        outer.route(to: .child(tabs))
        outer.activated()
        leaf.route(to: .screen(1))
        leaf.present(.screen(2))
        #expect(outer.bindingStack(for: .push).wrappedValue.count == 2)
        #expect(outer.modalDestinations(for: .sheet).count == 1)
    }

    @Test func dynamicallyAddedTabReleasesPayload() {
        let tabs = RevalidationTabs(RevalidationFlow()).activated()
        weak var weakChild: RevalidationFlow?
        do {
            let child = RevalidationFlow()
            weakChild = child
            tabs.appendTab(.child(child))
        }
        tabs.removeLastTab(.child)
        #expect(weakChild == nil)
    }

    @Test func pushedTabsTraverseRootWrapper() {
        let leaf = RevalidationFlow()
        let wrapper = RevalidationRoot(leaf)
        let tabs = RevalidationTabs(wrapper)
        let outer = RevalidationFlow()
        outer.route(to: .child(tabs))
        outer.activated()
        leaf.route(to: .screen(1))
        #expect(leaf.hasLayerNavigationCoordinatable)
        #expect(outer.bindingStack(for: .push).wrappedValue.count == 2)
        leaf.present(.screen(2))
        #expect(outer.modalDestinations(for: .sheet).count == 1)
    }

    @Test func preactivatedWrapperAdoptsNavigationLayer() {
        let leaf = RevalidationFlow()
        let wrapper = RevalidationRoot(leaf).activated()
        let outer = RevalidationFlow()
        outer.route(to: .child(wrapper))
        leaf.route(to: .screen(1))
        #expect(leaf.hasLayerNavigationCoordinatable)
        #expect(outer.bindingStack(for: .push).wrappedValue.count == 2)
    }

    @Test func reusedWrapperAdoptsIndependentNavigationLayer() {
        let leaf = RevalidationFlow()
        let wrapper = RevalidationRoot(leaf)
        let outer = RevalidationFlow()
        outer.route(to: .child(wrapper))
        outer.activated()
        outer.pop()
        outer.present(.child(wrapper))
        #expect(!wrapper.hasLayerNavigationCoordinatable)
        #expect(!leaf.hasLayerNavigationCoordinatable)
    }

    @Test func dismissPresentedModalClosesTheVisibleSheet() throws {
        let flow = RevalidationFlow()
        flow.present(.screen(1))
        flow.present(.screen(2))
        let visible = try #require(flow.modalDestinations(for: .sheet).first)
        flow.dismissPresentedModal()
        #expect(!flow.stack.destinations.contains { $0.id == visible.id })
    }

    @Test func tabMembershipBeforeActivation() {
        let tabs = RevalidationTabs(RevalidationFlow())
        #expect(tabs.isInTabItems(.child))
        _ = tabs.badge(for: .child)
        #expect(tabs.isInTabItems(.child))
    }

    @Test func tabsReleaseRemovedInitialRoutePayload() {
        weak var weakChild: RevalidationFlow?
        let tabs: RevalidationTabs
        do {
            let child = RevalidationFlow()
            weakChild = child
            tabs = RevalidationTabs(child).activated()
        }
        tabs.removeFirstTab(.child)
        #expect(weakChild == nil)
    }

    @Test func poppedChildStillCanUseDestinationAfterBeingReusedAsRoot() throws {
        let child = RevalidationFlow()
        let outer = RevalidationFlow()
        outer.present(.child(child))
        child.activated()
        outer.dismissModal()
        let top = RevalidationRoot(child).activated()
        let destination = try #require(child.stack.root)
        #expect(!destination.resolution.didResolve)
        #expect(destination.presentationType == .root)
        _ = top
    }
}

