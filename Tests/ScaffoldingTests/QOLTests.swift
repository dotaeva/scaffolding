//
//  QOLTests.swift
//  ScaffoldingTests
//
//  Tests for stack introspection, pop(count:), replaceLast, dismissAllModals,
//  RoutePolicy, seeded paths, sheet configuration, tab badges, expecting:
//  overloads, debugHierarchy, and Navigator.
//

import Testing
import SwiftUI
import Observation
@testable import Scaffolding

// MARK: - Seeded coordinator

@MainActor @Observable
final class SeededFlowCoordinator: FlowCoordinatable {
    var stack: FlowStack<SeededFlowCoordinator>

    init(pushing path: [Destinations] = []) {
        self.stack = FlowStack<SeededFlowCoordinator>(root: .home, pushing: path)
    }

    func home() -> some View { EmptyView() }
    func detail(id: Int) -> some View { EmptyView() }
    func child() -> any Coordinatable { LeafFlowCoordinator() }

    enum Destinations: Destinationable {
        typealias Owner = SeededFlowCoordinator
        case home
        case detail(id: Int)
        case child

        enum Meta: DestinationMeta {
            case home
            case detail
            case child
        }

        var meta: Meta {
            switch self {
            case .home: return .home
            case .detail: return .detail
            case .child: return .child
            }
        }

        func value(for instance: Owner) -> Destination {
            switch self {
            case .home:
                return Destination(instance.home(), meta: meta, parent: instance)
            case .detail(let id):
                return Destination(instance.detail(id: id), meta: meta, parent: instance)
            case .child:
                return Destination({ instance.child() }, meta: meta, parent: instance)
            }
        }
    }
}

// MARK: - Introspection

@MainActor
@Suite("Stack introspection")
struct IntrospectionTests {

    @Test("depth counts pushes only")
    func depthCountsPushes() {
        let flow = HomeFlowCoordinator()
        _ = flow.anyStack
        #expect(flow.depth == 0)

        flow.route(to: .settings)
        flow.route(to: .settings)
        flow.present(.sheetFlow)

        #expect(flow.depth == 2)
    }

    @Test("topDestination reflects the top push, falling back to the root")
    func topDestination() {
        let flow = HomeFlowCoordinator()
        #expect(flow.topDestination == .home)

        flow.route(to: .settings)
        #expect(flow.topDestination == .settings)

        flow.present(.sheetFlow)
        #expect(flow.topDestination == .settings) // modals ignored

        flow.dismissModal()
        flow.pop()
        #expect(flow.topDestination == .home)
    }

    @Test("isPresentingModal on flow, root, and tab coordinators")
    func isPresentingModal() {
        let flow = HomeFlowCoordinator()
        _ = flow.anyStack
        #expect(!flow.isPresentingModal)
        flow.present(.sheetFlow)
        #expect(flow.isPresentingModal)

        let app = AppRootCoordinator()
        #expect(!app.isPresentingModal)
        app.present(.login)
        #expect(app.isPresentingModal)

        let tabs = MainTabCoordinator()
        #expect(!tabs.isPresentingModal)
        tabs.present(.settings)
        #expect(tabs.isPresentingModal)
    }

    @Test("count(of:) counts occurrences in the stack")
    func countOf() {
        let flow = HomeFlowCoordinator()
        _ = flow.anyStack
        flow.route(to: .settings)
        flow.route(to: .detail)
        flow.route(to: .settings)

        #expect(flow.count(of: .settings) == 2)
        #expect(flow.count(of: .detail) == 1)
        #expect(flow.count(of: .home) == 0) // root not counted
    }
}

// MARK: - pop(count:) and replaceLast

@MainActor
@Suite("pop(count:) and replaceLast")
struct PopAndReplaceTests {

    @Test("pop(count:) removes exactly count destinations and fires onDismiss")
    func popCount() {
        let flow = HomeFlowCoordinator()
        _ = flow.anyStack
        var dismissed = 0
        flow.route(to: .settings, onDismiss: { dismissed += 1 })
        flow.route(to: .settings, onDismiss: { dismissed += 1 })
        flow.route(to: .settings, onDismiss: { dismissed += 1 })

        flow.pop(2)
        #expect(flow.anyStack.destinations.count == 1)
        #expect(dismissed == 2)
    }

    @Test("pop(count:) stops at the root and never dismisses the coordinator")
    func popCountStopsAtRoot() {
        let flow = HomeFlowCoordinator()
        _ = flow.anyStack
        flow.route(to: .settings)

        flow.pop(10)
        #expect(flow.anyStack.destinations.isEmpty)
        #expect(flow.anyStack.root != nil)

        flow.pop(1) // already empty — must be a no-op
        #expect(flow.anyStack.root != nil)
    }

    @Test("replaceLast swaps the top push and resolves the replaced destination")
    func replaceLast() {
        let flow = HomeFlowCoordinator()
        _ = flow.anyStack
        var replacedDismissed = false
        flow.route(to: .settings)
        flow.route(to: .detail, onDismiss: { replacedDismissed = true })

        flow.replaceLast(with: .settings)

        #expect(flow.anyStack.destinations.count == 2)
        #expect(flow.topDestination == .settings)
        #expect(replacedDismissed)
    }

    @Test("replaceLast on an empty stack pushes instead")
    func replaceLastFallsBackToPush() {
        let flow = HomeFlowCoordinator()
        _ = flow.anyStack

        flow.replaceLast(with: .settings)

        #expect(flow.anyStack.destinations.count == 1)
        #expect(flow.topDestination == .settings)
        #expect(flow.anyStack.root != nil)
    }

    @Test("replaceLast replaces the top push even under a presented modal")
    func replaceLastIgnoresModals() {
        let flow = HomeFlowCoordinator()
        _ = flow.anyStack
        flow.route(to: .detail)
        flow.present(.sheetFlow)

        flow.replaceLast(with: .settings)

        #expect(flow.topDestination == .settings)
        #expect(flow.isPresentingModal)
    }
}

// MARK: - dismissAllModals

@MainActor
@Suite("dismissAllModals")
struct DismissAllModalsTests {

    @Test("flow: removes every modal, keeps pushes, fires each onDismiss once")
    func flowDismissAll() {
        let flow = HomeFlowCoordinator()
        _ = flow.anyStack
        var dismissed = 0
        flow.route(to: .settings)
        flow.present(.sheetFlow, onDismiss: { dismissed += 1 })
        flow.present(.detail, as: .fullScreenCover, onDismiss: { dismissed += 1 })

        flow.dismissAllModals()

        #expect(!flow.isPresentingModal)
        #expect(flow.depth == 1)
        #expect(dismissed == 2)
    }

    @Test("root: clears the modal container")
    func rootDismissAll() {
        let app = AppRootCoordinator()
        var dismissed = 0
        app.present(.login, onDismiss: { dismissed += 1 })
        app.present(.main, onDismiss: { dismissed += 1 })

        app.dismissAllModals()

        #expect(app.anyRoot.modals.isEmpty)
        #expect(dismissed == 2)
    }

    @Test("no-op without modals")
    func noopWithoutModals() {
        let tabs = MainTabCoordinator()
        tabs.dismissAllModals()
        #expect(tabs.anyTabItems.modals.isEmpty)
    }
}

// MARK: - RoutePolicy

@MainActor
@Suite("RoutePolicy.distinct")
struct RoutePolicyTests {

    @Test("skips a push when the same case is already on top")
    func distinctSkipsDuplicateTop() {
        let flow = HomeFlowCoordinator()
        _ = flow.anyStack
        flow.route(to: .settings, policy: .distinct)
        flow.route(to: .settings, policy: .distinct)

        #expect(flow.anyStack.destinations.count == 1)
    }

    @Test("allows the same case when it is not on top")
    func distinctAllowsNonTopDuplicates() {
        let flow = HomeFlowCoordinator()
        _ = flow.anyStack
        flow.route(to: .settings, policy: .distinct)
        flow.route(to: .detail, policy: .distinct)
        flow.route(to: .settings, policy: .distinct)

        #expect(flow.anyStack.destinations.count == 3)
    }

    @Test("treats the root as the top when nothing is pushed")
    func distinctAgainstRoot() {
        let flow = HomeFlowCoordinator()
        _ = flow.anyStack
        flow.route(to: .home, policy: .distinct)

        #expect(flow.anyStack.destinations.isEmpty)
    }

    @Test(".always keeps duplicate pushes")
    func alwaysAllowsDuplicates() {
        let flow = HomeFlowCoordinator()
        _ = flow.anyStack
        flow.route(to: .settings)
        flow.route(to: .settings)

        #expect(flow.anyStack.destinations.count == 2)
    }

    @Test("skips a modal presentation when the same case is already presented")
    func distinctSkipsDuplicateModal() {
        let flow = HomeFlowCoordinator()
        _ = flow.anyStack
        flow.present(.sheetFlow, policy: .distinct)
        flow.present(.sheetFlow, policy: .distinct)

        #expect(flow.anyStack.destinations.count == 1)

        let app = AppRootCoordinator()
        app.present(.login, policy: .distinct)
        app.present(.login, policy: .distinct)
        #expect(app.anyRoot.modals.count == 1)

        let tabs = MainTabCoordinator()
        tabs.present(.settings, policy: .distinct)
        tabs.present(.settings, policy: .distinct)
        #expect(tabs.anyTabItems.modals.count == 1)
    }
}

// MARK: - Seeded initial path

@MainActor
@Suite("FlowStack(root:pushing:)")
struct SeededPathTests {

    @Test("materialises the seeded path at setup")
    func seedsPath() {
        let flow = SeededFlowCoordinator(pushing: [.detail(id: 1), .detail(id: 2)])
        _ = flow.anyStack

        #expect(flow.depth == 2)
        #expect(flow.topDestination == .detail)
        #expect(flow.anyStack.destinations.allSatisfy { $0.pushType == .push })
        #expect(flow.anyStack.root != nil)
    }

    @Test("seeded coordinator destinations get parent and layer wiring")
    func seededChildWiring() {
        let flow = SeededFlowCoordinator(pushing: [.child])
        _ = flow.anyStack

        let child = flow.anyStack.destinations.first?.coordinatable
        #expect(child?.parent === flow)
        #expect(child?.hasLayerNavigationCoordinatable == true)
    }

    @Test("empty path behaves like the plain initializer")
    func emptyPath() {
        let flow = SeededFlowCoordinator(pushing: [])
        _ = flow.anyStack
        #expect(flow.depth == 0)
    }
}

// MARK: - Sheet configuration

@MainActor
@Suite("Presenter-side sheet configuration")
struct SheetConfigurationTests {

    @Test("configured sheet carries detents and dismissal settings")
    func configuredSheet() {
        let flow = HomeFlowCoordinator()
        _ = flow.anyStack
        flow.present(.sheetFlow, as: .sheet(
            detents: [.medium, .large],
            dragIndicator: .visible,
            interactiveDismissDisabled: true
        ))

        let config = flow.anyStack.destinations.first?.modalConfiguration
        #expect(config?.detents == [.medium, .large])
        #expect(config?.dragIndicator == .visible)
        #expect(config?.interactiveDismissDisabled == true)
    }

    @Test("plain .sheet has no configuration")
    func plainSheet() {
        let flow = HomeFlowCoordinator()
        _ = flow.anyStack
        flow.present(.sheetFlow)

        #expect(flow.anyStack.destinations.first?.modalConfiguration == nil)
        #expect(flow.anyStack.destinations.first?.pushType == .sheet)
    }

    @Test("configured sheet on root and tab coordinators")
    func containerConfiguredSheet() {
        let app = AppRootCoordinator()
        app.present(.login, as: .sheet(detents: [.medium]))
        #expect(app.anyRoot.modals.first?.modalConfiguration?.detents == [.medium])

        let tabs = MainTabCoordinator()
        tabs.present(.settings, as: .sheet(interactiveDismissDisabled: true))
        #expect(tabs.anyTabItems.modals.first?.modalConfiguration?.interactiveDismissDisabled == true)
    }
}

// MARK: - Tab badges

@MainActor
@Suite("Tab badges")
struct TabBadgeTests {

    @Test("set, read, and clear a text badge")
    func textBadge() {
        let tabs = MainTabCoordinator()

        tabs.setBadge("3", for: .home)
        #expect(tabs.badge(for: .home) == "3")
        #expect(tabs.anyTabItems.tabs[0].badge == "3")
        #expect(tabs.badge(for: .profile) == nil)

        tabs.setBadge(nil, for: .home)
        #expect(tabs.badge(for: .home) == nil)
    }

    @Test("numeric badge: 0 clears, like SwiftUI's badge(_:)")
    func numericBadge() {
        let tabs = MainTabCoordinator()

        tabs.setBadge(12, for: .profile)
        #expect(tabs.badge(for: .profile) == "12")

        tabs.setBadge(0, for: .profile)
        #expect(tabs.badge(for: .profile) == nil)
    }

    @Test("badging a missing tab is a no-op")
    func missingTab() {
        let tabs = MainTabCoordinator()
        tabs.setBadge("1", for: .settings) // not in the tab bar
        #expect(tabs.badge(for: .settings) == nil)
    }
}

// MARK: - expecting: overloads

@MainActor
@Suite("Typed child resolution (expecting:)")
struct ExpectingTests {

    @Test("route returns the resolved child coordinator")
    func routeExpecting() {
        let flow = HomeFlowCoordinator()
        _ = flow.anyStack

        let detail = flow.route(to: .detail, expecting: DetailFlowCoordinator.self)
        #expect(detail != nil)
        #expect(detail?.parent === flow)
        #expect(flow.anyStack.destinations.count == 1)
    }

    @Test("mismatched type returns nil but the route still happens")
    func routeExpectingMismatch() {
        let flow = HomeFlowCoordinator()
        _ = flow.anyStack

        let wrong = flow.route(to: .detail, expecting: LeafFlowCoordinator.self)
        #expect(wrong == nil)
        #expect(flow.anyStack.destinations.count == 1)
    }

    @Test("view-only destination returns nil")
    func routeExpectingViewOnly() {
        let flow = HomeFlowCoordinator()
        _ = flow.anyStack

        let none = flow.route(to: .settings, expecting: DetailFlowCoordinator.self)
        #expect(none == nil)
    }

    @Test("deep-link chain: setRoot → selectFirstTab → route")
    func deepLinkChain() {
        let app = AppRootCoordinator()
        _ = app.anyRoot

        let tabs = app.setRoot(.main, expecting: MainTabCoordinator.self)
        #expect(tabs != nil)

        let home = tabs?.selectFirstTab(.home, expecting: HomeFlowCoordinator.self)
        #expect(home != nil)

        home?.route(to: .settings)
        #expect(home?.depth == 1)
    }

    @Test("present returns the presented coordinator across all coordinator kinds")
    func presentExpecting() {
        let flow = HomeFlowCoordinator()
        _ = flow.anyStack
        #expect(flow.present(.sheetFlow, expecting: LeafFlowCoordinator.self) != nil)

        let app = AppRootCoordinator()
        #expect(app.present(.login, expecting: LoginFlowCoordinator.self) != nil)

        let tabs = MainTabCoordinator()
        #expect(tabs.present(.settings, expecting: SettingsFlowCoordinator.self) != nil)
    }

    @Test("popToFirst/popToLast return the matched coordinator")
    func popExpecting() {
        let flow = HomeFlowCoordinator()
        _ = flow.anyStack
        flow.route(to: .detail)
        flow.route(to: .settings)

        let detail = flow.popToFirst(.detail, expecting: DetailFlowCoordinator.self)
        #expect(detail != nil)
        #expect(flow.anyStack.destinations.count == 1)
    }
}

// MARK: - debugHierarchy

@MainActor
@Suite("debugHierarchy")
struct DebugHierarchyTests {

    @Test("renders the tree with roles, metas, and child coordinators")
    func rendersTree() {
        let app = AppRootCoordinator()
        _ = app.anyRoot
        let tabs = app.anyRoot.root?.coordinatable as? MainTabCoordinator
        _ = tabs?.anyTabItems
        let home = tabs?.anyTabItems.tabs.first?.coordinatable as? HomeFlowCoordinator
        home?.route(to: .settings)
        home?.present(.sheetFlow)

        let dump = app.debugHierarchy()

        #expect(dump.contains("AppRootCoordinator [root]"))
        #expect(dump.contains("root .main → MainTabCoordinator [tab]"))
        #expect(dump.contains("tab[0]* .home → HomeFlowCoordinator [flow]"))
        #expect(dump.contains("push .settings"))
        #expect(dump.contains("sheet .sheetFlow"))
    }

    @Test("renders every tab, marking the selected one")
    func rendersAllTabs() {
        let tabs = MainTabCoordinator()
        _ = tabs.anyTabItems

        let dump = tabs.debugHierarchy()

        #expect(dump.contains("tab[0]* .home"))
        #expect(dump.contains("tab[1] .profile → ProfileFlowCoordinator [flow]"))
    }
}

// MARK: - Navigator

@MainActor
@Suite("Navigator")
struct NavigatorTests {

    @Test("pop and popToRoot act on the flow coordinator")
    func popActions() {
        let flow = HomeFlowCoordinator()
        _ = flow.anyStack
        flow.route(to: .settings)
        flow.route(to: .settings)

        let navigator = Navigator(flow)
        navigator.pop()
        #expect(flow.depth == 1)

        navigator.popToRoot()
        #expect(flow.depth == 0)
    }

    @Test("dismissModal and dismissAllModals act on the nearest coordinator")
    func modalActions() {
        let app = AppRootCoordinator()
        app.present(.login)
        app.present(.main)

        let navigator = Navigator(app)
        navigator.dismissModal()
        #expect(app.anyRoot.modals.count == 1)

        navigator.dismissAllModals()
        #expect(app.anyRoot.modals.isEmpty)
    }

    @Test("dismissCoordinator(returning:) delivers a result")
    func dismissReturning() async {
        let flow = HomeFlowCoordinator()
        _ = flow.anyStack

        let waiter = Task { await flow.present(.sheetFlow, awaiting: String.self) }
        while flow.anyStack.destinations.isEmpty { await Task.yield() }

        let leaf = flow.anyStack.destinations.first?.coordinatable as? LeafFlowCoordinator
        if let leaf {
            Navigator(leaf).dismissCoordinator(returning: "done")
        }

        let result = await waiter.value
        #expect(result == "done")
    }

    @Test("default navigator is a safe no-op")
    func defaultNoop() {
        let navigator = Navigator()
        navigator.pop()
        navigator.popToRoot()
        navigator.dismissModal()
        navigator.dismissAllModals()
        navigator.dismissCoordinator()
        #expect(navigator.coordinator == nil)
    }
}
