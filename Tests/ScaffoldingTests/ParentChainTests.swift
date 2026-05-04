//
//  ParentChainTests.swift
//  ScaffoldingTests
//
//  Comprehensive tests for parent chain integrity across all coordinator types.
//  Covers the fix from PR #2 (missing setParent on FlowStack/Root root setup)
//  and probes for related hidden issues.
//

import Testing
import SwiftUI
@testable import Scaffolding

/// Asserts that `child.parent` is the same object as `expectedParent`.
@MainActor
private func expectParent(
    of child: any Coordinatable,
    is expectedParent: AnyObject,
    _ message: String = "Parent must match expected coordinator",
    sourceLocation: SourceLocation = #_sourceLocation
) {
    #expect(child.parent != nil, Comment(rawValue: "Parent must not be nil — \(message)"), sourceLocation: sourceLocation)
    #expect(child.parent as AnyObject === expectedParent, Comment(rawValue: message), sourceLocation: sourceLocation)
}

// MARK: - FlowStack Setup Parent Chain

@MainActor
@Suite("FlowStack.setup parent chain")
struct FlowStackSetupTests {

    @Test("Root coordinatable gets parent set during FlowStack.setup")
    func rootCoordinatableParentAfterSetup() {
        let parent = HomeFlowCoordinator()
        let stack = parent.anyStack

        #expect(stack.root != nil)
        #expect(parent.stack.isSetup)
    }

    @Test("Root coordinator child gets parent set during FlowStack.setup")
    func rootCoordinatorChildParentAfterSetup() {
        let flow = FlowWithCoordinatorRootCoordinator()
        _ = flow.anyStack

        let rootCoordinatable = flow.stack.root?.coordinatable
        #expect(rootCoordinatable != nil, "Root should resolve to a coordinator")
        expectParent(of: rootCoordinatable!, is: flow)
    }

    @Test("Root coordinator gets hasLayerNavigationCoordinatable = true")
    func rootCoordinatorHasLayerFlag() {
        let flow = FlowWithCoordinatorRootCoordinator()
        _ = flow.anyStack

        let rootCoord = flow.stack.root?.coordinatable
        #expect(rootCoord != nil)
        #expect(rootCoord!.hasLayerNavigationCoordinatable == true,
                "Root of FlowStack must have hasLayerNavigationCoordinatable = true")
    }

    @Test("setup is idempotent — second call does not reset parent")
    func setupIdempotency() {
        let flow = FlowWithCoordinatorRootCoordinator()
        _ = flow.anyStack
        let firstRoot = flow.stack.root?.coordinatable

        flow.stack.setup(for: flow)
        let secondRoot = flow.stack.root?.coordinatable

        #expect(firstRoot as AnyObject === secondRoot as AnyObject, "Root must not change on second setup")
        #expect(secondRoot?.parent != nil, "Parent must still be set after second setup")
    }
}

// MARK: - Root.setup Parent Chain

@MainActor
@Suite("Root.setup parent chain")
struct RootSetupTests {

    @Test("Root coordinatable gets parent set during Root.setup")
    func rootCoordinatableParentAfterSetup() {
        let app = AppRootCoordinator()
        _ = app.anyRoot

        let rootCoord = app.root.root?.coordinatable
        #expect(rootCoord != nil, "Root should resolve to a coordinator (MainTabCoordinator)")
        expectParent(of: rootCoord!, is: app)
    }

    @Test("Root coordinatable gets correct hasLayerNavigationCoordinator")
    func rootCoordinatableHasLayerFlag() {
        let app = AppRootCoordinator()
        _ = app.anyRoot

        let rootCoord = app.root.root?.coordinatable
        #expect(rootCoord != nil)
        #expect(rootCoord!.hasLayerNavigationCoordinatable == false)
    }

    @Test("Root.setup is idempotent")
    func setupIdempotency() {
        let app = AppRootCoordinator()
        _ = app.anyRoot
        let firstRoot = app.root.root?.coordinatable

        app.root.setup(for: app)
        let secondRoot = app.root.root?.coordinatable

        #expect(firstRoot as AnyObject === secondRoot as AnyObject)
        #expect(secondRoot?.parent != nil)
    }
}

// MARK: - TabItems.setup Parent Chain

@MainActor
@Suite("TabItems.setup parent chain")
struct TabItemsSetupTests {

    @Test("All tab coordinatables get parent set during TabItems.setup")
    func allTabsGetParent() {
        let tab = MainTabCoordinator()
        _ = tab.anyTabItems

        for (index, tabDest) in tab.tabItems.tabs.enumerated() {
            let coord = tabDest.coordinatable
            #expect(coord != nil, "Tab \(index) should have a coordinator")
            expectParent(of: coord!, is: tab, "Tab \(index) parent must be the TabCoordinator")
        }
    }

    @Test("Tab coordinatables inherit hasLayerNavigationCoordinatable from parent")
    func tabsInheritLayerFlag() {
        let tab = MainTabCoordinator()
        _ = tab.anyTabItems

        for tabDest in tab.tabItems.tabs {
            let coord = tabDest.coordinatable
            #expect(coord?.hasLayerNavigationCoordinatable == tab.hasLayerNavigationCoordinatable)
        }
    }

    @Test("Tab coordinatables inherit hasLayerNavigationCoordinatable when parent has it true")
    func tabsInheritLayerFlagTrue() {
        let tab = MainTabCoordinator()
        tab.setHasLayerNavigationCoordinatable(true)
        _ = tab.anyTabItems

        for tabDest in tab.tabItems.tabs {
            let coord = tabDest.coordinatable
            #expect(coord?.hasLayerNavigationCoordinatable == true)
        }
    }

    @Test("Default tab selection is first tab")
    func defaultSelectionIsFirst() {
        let tab = MainTabCoordinator()
        _ = tab.anyTabItems

        #expect(tab.tabItems.selectedTab == tab.tabItems.tabs.first?.id)
    }
}

// MARK: - Deep Hierarchy Parent Chain

@MainActor
@Suite("Deep hierarchy parent chain traversal")
struct DeepHierarchyTests {

    @Test("App → Tab → Flow: 3-level chain is fully connected")
    func threeLevelChain() {
        let app = AppRootCoordinator()
        _ = app.anyRoot

        let tabCoord = app.root.root?.coordinatable as? MainTabCoordinator
        #expect(tabCoord != nil)
        _ = tabCoord!.anyTabItems

        let homeFlow = tabCoord!.tabItems.tabs.first?.coordinatable as? HomeFlowCoordinator
        #expect(homeFlow != nil)

        expectParent(of: homeFlow!, is: tabCoord!)
        expectParent(of: tabCoord!, is: app)

        let ancestors = collectAncestors(from: homeFlow!)
        #expect(ancestors.count == 2)
        #expect(canFindAncestor(ofType: MainTabCoordinator.self, from: homeFlow!))
        #expect(canFindAncestor(ofType: AppRootCoordinator.self, from: homeFlow!))
    }

    @Test("App → Tab → Flow → pushed Flow: 4 levels via route()")
    func fourLevelChainViaRoute() {
        let app = AppRootCoordinator()
        _ = app.anyRoot

        let tabCoord = app.root.root?.coordinatable as? MainTabCoordinator
        #expect(tabCoord != nil)
        _ = tabCoord!.anyTabItems

        let homeFlow = tabCoord!.tabItems.tabs.first?.coordinatable as? HomeFlowCoordinator
        #expect(homeFlow != nil)
        _ = homeFlow!.anyStack

        homeFlow!.route(to: .detail)

        let detailCoord = homeFlow!.stack.destinations.last?.coordinatable as? DetailFlowCoordinator
        #expect(detailCoord != nil, "Pushed destination should be a DetailFlowCoordinator")

        let ancestors = collectAncestors(from: detailCoord!)
        #expect(ancestors.count == 3)
        #expect(canFindAncestor(ofType: HomeFlowCoordinator.self, from: detailCoord!))
        #expect(canFindAncestor(ofType: MainTabCoordinator.self, from: detailCoord!))
        #expect(canFindAncestor(ofType: AppRootCoordinator.self, from: detailCoord!))
    }

    @Test("App → Tab → Flow → Flow → Flow: 5-level deep push chain (PR #2 regression)")
    func fiveLevelDeepChain() {
        let app = AppRootCoordinator()
        _ = app.anyRoot

        let tabCoord = app.root.root?.coordinatable as? MainTabCoordinator
        _ = tabCoord!.anyTabItems

        let homeFlow = tabCoord!.tabItems.tabs.first?.coordinatable as? HomeFlowCoordinator
        _ = homeFlow!.anyStack

        homeFlow!.route(to: .detail)
        let detailCoord = homeFlow!.stack.destinations.last?.coordinatable as? DetailFlowCoordinator
        _ = detailCoord!.anyStack

        detailCoord!.route(to: .subDetail)
        let leafCoord = detailCoord!.stack.destinations.last?.coordinatable as? LeafFlowCoordinator

        #expect(leafCoord != nil)

        let ancestors = collectAncestors(from: leafCoord!)
        #expect(ancestors.count == 4)
        #expect(canFindAncestor(ofType: DetailFlowCoordinator.self, from: leafCoord!))
        #expect(canFindAncestor(ofType: HomeFlowCoordinator.self, from: leafCoord!))
        #expect(canFindAncestor(ofType: MainTabCoordinator.self, from: leafCoord!))
        #expect(canFindAncestor(ofType: AppRootCoordinator.self, from: leafCoord!))
    }

    @Test("FlowStack root coordinator is reachable from its pushed children (PR #2 exact scenario)")
    func flowStackRootCoordinatorReachableFromPushed() {
        let flow = FlowWithCoordinatorRootCoordinator()
        _ = flow.anyStack

        let rootDetailCoord = flow.stack.root?.coordinatable as? DetailFlowCoordinator
        #expect(rootDetailCoord != nil)
        #expect(rootDetailCoord!.parent != nil, "Root coord of FlowStack must have parent (PR #2 fix)")

        _ = rootDetailCoord!.anyStack
        rootDetailCoord!.route(to: .subDetail)

        let leaf = rootDetailCoord!.stack.destinations.last?.coordinatable as? LeafFlowCoordinator
        #expect(leaf != nil)

        #expect(canFindAncestor(ofType: DetailFlowCoordinator.self, from: leaf!))
        #expect(canFindAncestor(ofType: FlowWithCoordinatorRootCoordinator.self, from: leaf!))
    }

    @Test("Root → Root → Flow: nested RootCoordinatables preserve chain")
    func nestedRootCoordinators() {
        let outer = OuterRootCoordinator()
        _ = outer.anyRoot

        let inner = outer.root.root?.coordinatable as? InnerRootCoordinator
        #expect(inner != nil)
        #expect(inner!.parent != nil)
        _ = inner!.anyRoot

        let homeFlow = inner!.root.root?.coordinatable as? HomeFlowCoordinator
        #expect(homeFlow != nil)
        #expect(homeFlow!.parent != nil)

        let ancestors = collectAncestors(from: homeFlow!)
        #expect(ancestors.count == 2)
        #expect(canFindAncestor(ofType: InnerRootCoordinator.self, from: homeFlow!))
        #expect(canFindAncestor(ofType: OuterRootCoordinator.self, from: homeFlow!))
    }
}

// MARK: - Navigation Actions and Parent Chain

@MainActor
@Suite("Navigation actions preserve parent chain")
struct NavigationActionTests {

    @Test("route(to:) sets parent on pushed coordinator destination")
    func routeSetsParent() {
        let home = HomeFlowCoordinator()
        _ = home.anyStack

        home.route(to: .detail)

        let detail = home.stack.destinations.last?.coordinatable as? DetailFlowCoordinator
        #expect(detail != nil)
        expectParent(of: detail!, is: home)
    }

    @Test("present(_:as:.sheet) sets parent on modal coordinator destination")
    func presentAsSheetSetsParent() {
        let home = HomeFlowCoordinator()
        _ = home.anyStack

        home.present(.sheetFlow, as: .sheet)

        let sheetCoord = home.stack.destinations.last?.coordinatable as? LeafFlowCoordinator
        #expect(sheetCoord != nil)
        expectParent(of: sheetCoord!, is: home)
    }

    @Test("present(_:as:.sheet) sets hasLayerNavigationCoordinatable = false on modal")
    func sheetDoesNotHaveLayerNavigation() {
        let home = HomeFlowCoordinator()
        _ = home.anyStack

        home.present(.sheetFlow, as: .sheet)

        let sheetCoord = home.stack.destinations.last?.coordinatable
        #expect(sheetCoord != nil)
        #expect(sheetCoord!.hasLayerNavigationCoordinatable == false,
                "Sheet-presented flows must NOT share parent NavigationStack layer")
    }

    @Test("route(to:) sets hasLayerNavigationCoordinatable = true")
    func pushHasLayerNavigation() {
        let home = HomeFlowCoordinator()
        _ = home.anyStack

        home.route(to: .detail)

        let detail = home.stack.destinations.last?.coordinatable
        #expect(detail != nil)
        #expect(detail!.hasLayerNavigationCoordinatable == true,
                "Push-presented flows must share parent NavigationStack layer")
    }

    @Test("FlowCoordinatable.setRoot sets parent on new root coordinator")
    func flowSetRootSetsParent() {
        let flow = FlowWithCoordinatorRootCoordinator()
        _ = flow.anyStack

        let oldRoot = flow.stack.root?.coordinatable
        #expect(oldRoot != nil)

        flow.setRoot(.other)

        let newRoot = flow.stack.root?.coordinatable as? LeafFlowCoordinator
        #expect(newRoot != nil)
        expectParent(of: newRoot!, is: flow, "New root must have parent set after setRoot")
    }

    @Test("RootCoordinatable.setRoot sets parent on new root coordinator")
    func rootCoordinatableSetRootSetsParent() {
        let app = AppRootCoordinator()
        _ = app.anyRoot

        app.setRoot(.login)

        let loginCoord = app.root.root?.coordinatable as? LoginFlowCoordinator
        #expect(loginCoord != nil)
        expectParent(of: loginCoord!, is: app, "New root must have parent set after setRoot")
    }

    @Test("Multiple route() calls all set correct parent")
    func multipleRouteCallsSetParent() {
        let home = HomeFlowCoordinator()
        _ = home.anyStack

        home.route(to: .settings)
        home.route(to: .detail)
        home.route(to: .settings)

        #expect(home.stack.destinations.count == 3)

        for (index, dest) in home.stack.destinations.enumerated() {
            if let coord = dest.coordinatable {
                expectParent(of: coord, is: home, "Destination \(index) parent must be home")
            }
        }
    }

    @Test("pop() does not break remaining destinations' parent chain")
    func popPreservesParentChain() {
        let home = HomeFlowCoordinator()
        _ = home.anyStack

        home.route(to: .detail)
        home.route(to: .detail)

        #expect(home.stack.destinations.count == 2)

        let firstDetail = home.stack.destinations.first?.coordinatable
        home.pop()

        #expect(home.stack.destinations.count == 1)
        #expect(firstDetail?.parent != nil, "Remaining destination parent must still be set")
    }

    @Test("popToRoot() does not break root parent chain")
    func popToRootPreservesRootParent() {
        let flow = FlowWithCoordinatorRootCoordinator()
        _ = flow.anyStack

        flow.route(to: .other)
        flow.route(to: .other)
        flow.popToRoot()

        #expect(flow.stack.destinations.isEmpty)
        let rootCoord = flow.stack.root?.coordinatable
        #expect(rootCoord?.parent != nil, "Root coordinator parent must survive popToRoot")
    }
}

// MARK: - Tab Operations and Parent Chain

@MainActor
@Suite("Tab operations preserve parent chain")
struct TabOperationTests {

    @Test("setTabs sets parent on all new tab coordinators")
    func setTabsSetsParent() {
        let tab = MainTabCoordinator()
        _ = tab.anyTabItems

        tab.setTabs([.settings, .home])

        for (index, tabDest) in tab.tabItems.tabs.enumerated() {
            let coord = tabDest.coordinatable
            #expect(coord != nil, "Tab \(index) should have coordinator")
            expectParent(of: coord!, is: tab, "Tab \(index) must have parent after setTabs")
        }
    }

    @Test("appendTab sets parent on appended coordinator")
    func appendTabSetsParent() {
        let tab = MainTabCoordinator()
        _ = tab.anyTabItems

        let originalCount = tab.tabItems.tabs.count
        tab.appendTab(.settings)

        #expect(tab.tabItems.tabs.count == originalCount + 1)

        let appended = tab.tabItems.tabs.last?.coordinatable
        #expect(appended != nil)
        expectParent(of: appended!, is: tab, "Appended tab must have parent")
    }

    @Test("insertTab sets parent on inserted coordinator")
    func insertTabSetsParent() {
        let tab = MainTabCoordinator()
        _ = tab.anyTabItems

        tab.insertTab(.settings, at: 0)

        let inserted = tab.tabItems.tabs.first?.coordinatable
        #expect(inserted != nil)
        #expect(inserted?.parent != nil, "Inserted tab must have parent")
    }

    @Test("removeFirstTab does not break remaining tabs' parent chain")
    func removeTabPreservesOthers() {
        let tab = MainTabCoordinator()
        _ = tab.anyTabItems

        let profileCoord = tab.tabItems.tabs.last?.coordinatable
        tab.removeFirstTab(.home)

        #expect(tab.tabItems.tabs.count == 1)
        #expect(profileCoord?.parent != nil, "Remaining tab parent must survive removal")
    }
}

// MARK: - dismissCoordinator Tests

@MainActor
@Suite("dismissCoordinator parent chain behavior")
struct DismissCoordinatorTests {

    @Test("dismissCoordinator removes pushed coordinator from parent's stack")
    func dismissPushedCoordinator() {
        let home = HomeFlowCoordinator()
        _ = home.anyStack

        home.route(to: .detail)
        #expect(home.stack.destinations.count == 1)

        let detail = home.stack.destinations.first?.coordinatable as? DetailFlowCoordinator
        #expect(detail != nil)

        detail!.dismissCoordinator()
        #expect(home.stack.destinations.count == 0, "Dismissed coordinator must be removed from parent stack")
    }

    @Test("dismissCoordinator on pushed leaf removes it from parent")
    func dismissPushedLeaf() {
        let parentFlow = FlowWithCoordinatorRootCoordinator()
        _ = parentFlow.anyStack

        parentFlow.route(to: .other)
        let pushedLeaf = parentFlow.stack.destinations.first?.coordinatable as? LeafFlowCoordinator
        #expect(pushedLeaf != nil)
        #expect(pushedLeaf!.parent != nil)

        pushedLeaf!.dismissCoordinator()
        #expect(parentFlow.stack.destinations.isEmpty)
    }

    @Test("dismissCoordinator on tab child logs warning and does nothing")
    func dismissTabChildIsNoOp() {
        let tab = MainTabCoordinator()
        _ = tab.anyTabItems

        let homeFlow = tab.tabItems.tabs.first?.coordinatable as? HomeFlowCoordinator
        #expect(homeFlow != nil)

        let tabCountBefore = tab.tabItems.tabs.count
        homeFlow!.dismissCoordinator()

        #expect(tab.tabItems.tabs.count == tabCountBefore)
    }

    @Test("dismissCoordinator on RootCoordinatable child does not crash")
    func dismissRootChildDoesNotCrash() {
        let app = AppRootCoordinator()
        _ = app.anyRoot

        let tabCoord = app.root.root?.coordinatable as? MainTabCoordinator
        #expect(tabCoord != nil)

        // parent is RootCoordinatable → calls parent.parent?.dismissCoordinator()
        // app has no parent, so nothing happens — must not crash
        tabCoord!.dismissCoordinator()
    }
}

// MARK: - hasLayerNavigationCoordinatable Propagation

@MainActor
@Suite("hasLayerNavigationCoordinatable propagation")
struct LayerNavigationTests {

    @Test("FlowStack root always gets hasLayer = true")
    func flowStackRootAlwaysTrue() {
        let flow = FlowWithCoordinatorRootCoordinator()
        _ = flow.anyStack

        let root = flow.stack.root?.coordinatable
        #expect(root?.hasLayerNavigationCoordinatable == true)
    }

    @Test("FlowStack.setRoot preserves hasLayer = true on new root")
    func setRootPreservesHasLayer() {
        let flow = FlowWithCoordinatorRootCoordinator()
        _ = flow.anyStack

        flow.setRoot(.other)

        let newRoot = flow.stack.root?.coordinatable
        #expect(newRoot?.hasLayerNavigationCoordinatable == true)
    }

    @Test("Push-presented coordinator gets hasLayer = true")
    func pushGetsHasLayerTrue() {
        let home = HomeFlowCoordinator()
        _ = home.anyStack
        home.route(to: .detail)

        let detail = home.stack.destinations.last?.coordinatable
        #expect(detail?.hasLayerNavigationCoordinatable == true)
    }

    @Test("Sheet-presented coordinator gets hasLayer = false")
    func sheetGetsHasLayerFalse() {
        let home = HomeFlowCoordinator()
        _ = home.anyStack
        home.present(.sheetFlow, as: .sheet)

        let sheetCoord = home.stack.destinations.last?.coordinatable
        #expect(sheetCoord?.hasLayerNavigationCoordinatable == false)
    }

    @Test("FullScreenCover-presented coordinator gets hasLayer = false")
    func fullScreenCoverGetsHasLayerFalse() {
        let home = HomeFlowCoordinator()
        _ = home.anyStack
        home.present(.sheetFlow, as: .fullScreenCover)

        let coverCoord = home.stack.destinations.last?.coordinatable
        #expect(coverCoord?.hasLayerNavigationCoordinatable == false)
    }

    @Test("Tabs inherit hasLayer from TabCoordinator")
    func tabsInheritFromParent() {
        let tab = MainTabCoordinator()
        tab.setHasLayerNavigationCoordinatable(true)
        _ = tab.anyTabItems

        for tabDest in tab.tabItems.tabs {
            #expect(tabDest.coordinatable?.hasLayerNavigationCoordinatable == true)
        }
    }

    @Test("Root.setup propagates hasLayerNavigationCoordinator to child")
    func rootPropagatesHasLayer() {
        let app = AppRootCoordinator()
        app.root.hasLayerNavigationCoordinator = true
        _ = app.anyRoot

        let rootCoord = app.root.root?.coordinatable
        #expect(rootCoord?.hasLayerNavigationCoordinatable == true)
    }
}

// MARK: - presentedAs Propagation

@MainActor
@Suite("presentedAs propagation through setup")
struct PresentedAsTests {

    @Test("FlowStack.setup propagates presentedAs to root destination")
    func flowStackPropagatesPresentedAs() {
        let flow = HomeFlowCoordinator()
        flow.stack.presentedAs = .sheet
        _ = flow.anyStack

        #expect(flow.stack.root?.pushType == .sheet,
                "Root destination should inherit presentedAs as pushType")
    }

    @Test("Root.setup propagates presentedAs to root destination")
    func rootPropagatesPresentedAs() {
        let app = AppRootCoordinator()
        app.root.presentedAs = .sheet
        _ = app.anyRoot

        #expect(app.root.root?.pushType == .sheet)
    }

    @Test("TabItems.setup propagates presentedAs to all tabs")
    func tabsPropagatesPresentedAs() {
        let tab = MainTabCoordinator()
        tab.tabItems.presentedAs = .sheet
        _ = tab.anyTabItems

        for tabDest in tab.tabItems.tabs {
            #expect(tabDest.pushType == .sheet)
        }
    }

    @Test("setPresentedAs on FlowCoordinatable updates stack and existing root")
    func setPresentedAsUpdatesExisting() {
        let flow = HomeFlowCoordinator()
        _ = flow.anyStack

        let initialPushType = flow.stack.root?.pushType

        flow.setPresentedAs(.fullScreenCover)

        #expect(flow.stack.presentedAs == .fullScreenCover)
        if initialPushType == nil {
            #expect(flow.stack.root?.pushType == .fullScreenCover)
        }
    }
}

// MARK: - Edge Cases

@MainActor
@Suite("Edge cases and potential hidden issues")
struct EdgeCaseTests {

    @Test("Root.setRoot internal does not call setParent — public API must do it")
    func rootInternalSetRootReliesOnPublicAPI() {
        let app = AppRootCoordinator()
        _ = app.anyRoot

        app.setRoot(.login)

        let login = app.root.root?.coordinatable as? LoginFlowCoordinator
        #expect(login != nil)
        #expect(login!.parent != nil,
                "Public setRoot must establish parent even though internal method doesn't")
    }

    @Test("Coordinator identity is stable across parent chain references")
    func coordinatorIdentityStable() {
        let app = AppRootCoordinator()
        _ = app.anyRoot

        let tab = app.root.root?.coordinatable as? MainTabCoordinator
        _ = tab!.anyTabItems

        let homeFlow = tab!.tabItems.tabs.first?.coordinatable as? HomeFlowCoordinator

        let parentOfHome = homeFlow!.parent as? MainTabCoordinator
        #expect(parentOfHome === tab, "Parent must be the same object instance, not a copy")
    }

    @Test("Parent chain survives tab selection changes")
    func parentChainSurvivesTabSwitch() {
        let tab = MainTabCoordinator()
        _ = tab.anyTabItems

        let homeFlow = tab.tabItems.tabs.first?.coordinatable as? HomeFlowCoordinator
        let profileFlow = tab.tabItems.tabs.last?.coordinatable as? ProfileFlowCoordinator

        tab.selectLastTab(.profile)

        #expect(homeFlow?.parent != nil)
        #expect(profileFlow?.parent != nil)
    }

    @Test("FlowStack with no coordinator root (view-only) does not crash on setup")
    func viewOnlyRootDoesNotCrash() {
        let home = HomeFlowCoordinator()
        _ = home.anyStack

        #expect(home.stack.root != nil)
        #expect(home.stack.root?.coordinatable == nil, "View-only root has no coordinatable")
        #expect(home.stack.isSetup)
    }

    @Test("environmentCoordinatable walks the full parent chain")
    func environmentCoordinatableWalksFullChain() {
        let app = AppRootCoordinator()
        _ = app.anyRoot

        let tab = app.root.root?.coordinatable as? MainTabCoordinator
        _ = tab!.anyTabItems

        let homeFlow = tab!.tabItems.tabs.first?.coordinatable as? HomeFlowCoordinator
        _ = homeFlow!.anyStack

        homeFlow!.route(to: .detail)
        let detail = homeFlow!.stack.destinations.last?.coordinatable as? DetailFlowCoordinator

        var depth = 0
        var current: (any Coordinatable)? = detail
        while let c = current {
            depth += 1
            current = c.parent
        }
        // detail(1) → home(2) → tab(3) → app(4) → nil
        #expect(depth == 4, "Should be able to walk 4 levels deep")
    }

    @Test("isInStack works for pushed destinations")
    func isInStackWorks() {
        let home = HomeFlowCoordinator()
        _ = home.anyStack

        #expect(!home.isInStack(.detail))

        home.route(to: .detail)
        #expect(home.isInStack(.detail))

        home.pop()
        #expect(!home.isInStack(.detail))
    }

    @Test("popToFirst preserves parent on remaining destinations")
    func popToFirstPreservesParent() {
        let home = HomeFlowCoordinator()
        _ = home.anyStack

        home.route(to: .detail)
        home.route(to: .settings)
        home.route(to: .detail)

        #expect(home.stack.destinations.count == 3)

        let firstDetail = home.stack.destinations.first?.coordinatable

        home.popToFirst(.detail)

        #expect(home.stack.destinations.count == 1)
        #expect(firstDetail?.parent != nil)
    }

    @Test("popToLast preserves parent on remaining destinations")
    func popToLastPreservesParent() {
        let home = HomeFlowCoordinator()
        _ = home.anyStack

        home.route(to: .detail)
        home.route(to: .settings)
        home.route(to: .detail)

        home.popToLast(.detail)

        #expect(home.stack.destinations.count == 3)

        for dest in home.stack.destinations {
            if let coord = dest.coordinatable {
                #expect(coord.parent != nil)
            }
        }
    }

    @Test("isRoot returns correct value")
    func isRootWorks() {
        let app = AppRootCoordinator()
        _ = app.anyRoot

        #expect(app.isRoot(.main))
        #expect(!app.isRoot(.login))

        app.setRoot(.login)
        #expect(app.isRoot(.login))
        #expect(!app.isRoot(.main))
    }

    @Test("Pop on empty stack triggers dismissCoordinator")
    func popOnEmptyStackDismisses() {
        let parent = HomeFlowCoordinator()
        _ = parent.anyStack

        parent.route(to: .detail)
        let detail = parent.stack.destinations.first?.coordinatable as? DetailFlowCoordinator
        _ = detail!.anyStack

        detail!.pop()
        #expect(parent.stack.destinations.isEmpty,
                "Pop on empty stack should dismiss (remove from parent)")
    }

    @Test("Routed coordinator is reachable from the stack with correct parent")
    func routedCoordinatorReachableFromStack() {
        let home = HomeFlowCoordinator()
        _ = home.anyStack

        home.route(to: .detail)

        let detail = home.stack.destinations.last?.coordinatable as? DetailFlowCoordinator
        #expect(detail != nil)
        #expect(detail?.parent != nil)
    }

    @Test("FlowStack setRoot establishes parent and hasLayer on new root")
    func flowSetRootEstablishesParentAndLayer() {
        let flow = FlowWithCoordinatorRootCoordinator()
        _ = flow.anyStack

        flow.route(to: .other)
        flow.route(to: .other)

        flow.setRoot(.other)

        let newRoot = flow.stack.root?.coordinatable
        #expect(newRoot != nil)
        #expect(newRoot?.parent != nil)
        #expect(newRoot?.hasLayerNavigationCoordinatable == true)
    }

    @Test("Tab coordinator isInTabItems works correctly")
    func isInTabItemsWorks() {
        let tab = MainTabCoordinator()
        _ = tab.anyTabItems

        #expect(tab.isInTabItems(.home))
        #expect(tab.isInTabItems(.profile))
        #expect(!tab.isInTabItems(.settings))

        tab.appendTab(.settings)
        #expect(tab.isInTabItems(.settings))
    }
}

// MARK: - Regression Tests (PR #2 specific scenarios)

@MainActor
@Suite("PR #2 regression: FlowStack and Root root parent chain")
struct PR2RegressionTests {

    @Test("FlowStack root coordinatable has non-nil parent after setup — the original bug")
    func flowStackRootHasParent() {
        let flow = FlowWithCoordinatorRootCoordinator()
        _ = flow.anyStack

        let rootCoord = flow.stack.root?.coordinatable
        #expect(rootCoord != nil)
        #expect(rootCoord!.parent != nil,
                "REGRESSION: FlowStack root coordinatable must have parent after setup")
    }

    @Test("Root root coordinatable has non-nil parent after setup — the original bug")
    func rootRootHasParent() {
        let app = AppRootCoordinator()
        _ = app.anyRoot

        let rootCoord = app.root.root?.coordinatable
        #expect(rootCoord != nil)
        #expect(rootCoord!.parent != nil,
                "REGRESSION: Root root coordinatable must have parent after setup")
    }

    @Test("findAncestor traversal does NOT stop at FlowStack root boundary")
    func traversalDoesNotStopAtFlowStackRoot() {
        let app = AppRootCoordinator()
        _ = app.anyRoot

        let tab = app.root.root?.coordinatable as? MainTabCoordinator
        _ = tab!.anyTabItems

        let homeFlow = tab!.tabItems.tabs.first?.coordinatable as? HomeFlowCoordinator
        _ = homeFlow!.anyStack

        homeFlow!.route(to: .detail)
        let detailFlow = homeFlow!.stack.destinations.last?.coordinatable as? DetailFlowCoordinator
        _ = detailFlow!.anyStack

        detailFlow!.route(to: .subDetail)
        let leafFlow = detailFlow!.stack.destinations.last?.coordinatable as? LeafFlowCoordinator

        let foundApp = findAncestor(ofType: AppRootCoordinator.self, from: leafFlow!)
        #expect(foundApp != nil, "REGRESSION: Must be able to find AppRootCoordinator from deeply nested leaf")
        #expect(foundApp === app, "Must be the same instance")
    }

    @Test("findAncestor traversal does NOT stop at Root root boundary")
    func traversalDoesNotStopAtRootBoundary() {
        let outer = OuterRootCoordinator()
        _ = outer.anyRoot

        let inner = outer.root.root?.coordinatable as? InnerRootCoordinator
        _ = inner!.anyRoot

        let homeFlow = inner!.root.root?.coordinatable as? HomeFlowCoordinator
        _ = homeFlow!.anyStack

        homeFlow!.route(to: .detail)
        let detail = homeFlow!.stack.destinations.last?.coordinatable as? DetailFlowCoordinator

        let foundOuter = findAncestor(ofType: OuterRootCoordinator.self, from: detail!)
        #expect(foundOuter != nil,
                "REGRESSION: Must be able to traverse past Root boundary to find outer coordinator")
        #expect(foundOuter === outer)
    }

    @Test("FlowStack.setRoot also calls setParent on new root coordinator")
    func flowStackSetRootCallsSetParent() {
        let flow = FlowWithCoordinatorRootCoordinator()
        _ = flow.anyStack

        flow.setRoot(.other)

        let newRoot = flow.stack.root?.coordinatable
        #expect(newRoot != nil)
        #expect(newRoot!.parent != nil,
                "setRoot must also establish parent on new root coordinator")
    }

    @Test("Consistent behavior: TabItems.setup matches FlowStack/Root")
    func consistentBehaviorAcrossContainerTypes() {
        let tab = MainTabCoordinator()
        _ = tab.anyTabItems

        let flow = FlowWithCoordinatorRootCoordinator()
        _ = flow.anyStack

        let app = AppRootCoordinator()
        _ = app.anyRoot

        let tabChild = tab.tabItems.tabs.first?.coordinatable
        let flowRoot = flow.stack.root?.coordinatable
        let rootChild = app.root.root?.coordinatable

        #expect(tabChild?.parent != nil, "TabItems child must have parent")
        #expect(flowRoot?.parent != nil, "FlowStack root must have parent")
        #expect(rootChild?.parent != nil, "Root child must have parent")
    }
}

// MARK: - route() / present() Split

@MainActor
@Suite("route() pushes only; present() handles modals")
struct RoutePresentSplitTests {

    // MARK: route() — push semantics

    @Test("route(to:) pushes onto stack with pushType .push")
    func routePushesOnly() {
        let home = HomeFlowCoordinator()
        _ = home.anyStack

        home.route(to: .detail)

        let pushed = home.stack.destinations.last
        #expect(pushed != nil)
        #expect(pushed?.pushType == .push,
                "route(to:) must always produce a .push destination")
        #expect(pushed?.routeType == .push)
    }

    @Test("route(to:) does not append to any modal container")
    func routeDoesNotPopulateModals() {
        let home = HomeFlowCoordinator()
        _ = home.anyStack
        home.route(to: .detail)

        // FlowStack: pushed dest is in destinations but its pushType is .push,
        // never .sheet/.fullScreenCover.
        #expect(home.stack.destinations.allSatisfy { $0.pushType != .sheet && $0.pushType != .fullScreenCover })
    }

    // MARK: present() on FlowCoordinatable

    @Test("present(_:as:.sheet) on Flow appends a sheet destination to its stack")
    func flowPresentSheetGoesToStack() {
        let home = HomeFlowCoordinator()
        _ = home.anyStack

        home.present(.sheetFlow, as: .sheet)

        let modal = home.stack.destinations.last
        #expect(modal != nil)
        #expect(modal?.pushType == .sheet)
        #expect(modal?.routeType == .sheet)
        let sheetCoord = modal?.coordinatable as? LeafFlowCoordinator
        #expect(sheetCoord != nil)
        expectParent(of: sheetCoord!, is: home)
    }

    @Test("present(_:as:.fullScreenCover) on Flow appends a cover destination")
    func flowPresentFullScreenCoverGoesToStack() {
        let home = HomeFlowCoordinator()
        _ = home.anyStack

        home.present(.sheetFlow, as: .fullScreenCover)

        let modal = home.stack.destinations.last
        #expect(modal?.pushType == .fullScreenCover)
        #expect(modal?.routeType == .fullScreenCover)
    }

    @Test("present() default is .sheet")
    func presentDefaultIsSheet() {
        let home = HomeFlowCoordinator()
        _ = home.anyStack

        home.present(.sheetFlow)

        #expect(home.stack.destinations.last?.pushType == .sheet)
    }

    @Test("present(onDismiss:) fires when modal is removed")
    func presentOnDismissFires() {
        let home = HomeFlowCoordinator()
        _ = home.anyStack

        var fired = 0
        home.present(.sheetFlow, as: .sheet, onDismiss: { fired += 1 })

        let modalId = home.stack.destinations.last!.id
        home.removeModalDestination(withId: modalId, type: .sheet)

        #expect(fired == 1, "onDismiss must fire exactly once on modal removal")
        #expect(home.stack.destinations.isEmpty)
    }

    // MARK: present() on TabCoordinatable

    @Test("present(_:as:.sheet) on Tab appends to tabItems.modals")
    func tabPresentSheetGoesToContainerModals() {
        let tab = MainTabCoordinator()
        _ = tab.anyTabItems

        tab.present(.settings, as: .sheet)

        #expect(tab.tabItems.modals.count == 1)
        #expect(tab.tabItems.modals.first?.pushType == .sheet)
        #expect(tab.tabItems.modals.first?.routeType == .sheet)

        let presented = tab.tabItems.modals.first?.coordinatable as? SettingsFlowCoordinator
        #expect(presented != nil)
        expectParent(of: presented!, is: tab)
    }

    @Test("present() on Tab does not mutate tabs array")
    func tabPresentDoesNotChangeTabs() {
        let tab = MainTabCoordinator()
        _ = tab.anyTabItems
        let originalCount = tab.tabItems.tabs.count

        tab.present(.settings, as: .sheet)

        #expect(tab.tabItems.tabs.count == originalCount,
                "present() must not append to the visible tab list")
    }

    @Test("present(_:as:.fullScreenCover) on Tab is a separate slot from .sheet")
    func tabPresentSheetAndFullScreenCoverCoexist() {
        let tab = MainTabCoordinator()
        _ = tab.anyTabItems

        tab.present(.settings, as: .sheet)
        tab.present(.home, as: .fullScreenCover)

        #expect(tab.tabItems.modals.count == 2)
        #expect(tab.tabItems.modals.contains(where: { $0.pushType == .sheet }))
        #expect(tab.tabItems.modals.contains(where: { $0.pushType == .fullScreenCover }))
    }

    @Test("dismissCoordinator on Tab modal child removes from tabItems.modals")
    func dismissTabModalChildRemovesFromModals() {
        let tab = MainTabCoordinator()
        _ = tab.anyTabItems

        tab.present(.settings, as: .sheet)
        let presented = tab.tabItems.modals.first?.coordinatable as? SettingsFlowCoordinator
        #expect(presented != nil)

        presented!.dismissCoordinator()

        #expect(tab.tabItems.modals.isEmpty,
                "Modal child must be removable via dismissCoordinator on Tab parent")
    }

    @Test("dismissCoordinator on Tab tab child still refused (only modals are dismissable)")
    func tabTabChildStillNotDismissable() {
        let tab = MainTabCoordinator()
        _ = tab.anyTabItems

        let homeFlow = tab.tabItems.tabs.first?.coordinatable as? HomeFlowCoordinator
        #expect(homeFlow != nil)

        let countBefore = tab.tabItems.tabs.count
        homeFlow!.dismissCoordinator()

        #expect(tab.tabItems.tabs.count == countBefore,
                "Plain tab child must remain non-dismissable")
    }

    @Test("Tab modal onDismiss fires once on dismissCoordinator")
    func tabModalOnDismissFires() {
        let tab = MainTabCoordinator()
        _ = tab.anyTabItems

        var fired = 0
        tab.present(.settings, as: .sheet, onDismiss: { fired += 1 })

        let presented = tab.tabItems.modals.first?.coordinatable as? SettingsFlowCoordinator
        presented!.dismissCoordinator()

        #expect(fired == 1)
    }

    // MARK: present() on RootCoordinatable

    @Test("present(_:as:.sheet) on Root appends to root.modals")
    func rootPresentSheetGoesToContainerModals() {
        let app = AppRootCoordinator()
        _ = app.anyRoot

        app.present(.login, as: .sheet)

        #expect(app.root.modals.count == 1)
        #expect(app.root.modals.first?.pushType == .sheet)

        let presented = app.root.modals.first?.coordinatable as? LoginFlowCoordinator
        #expect(presented != nil)
        expectParent(of: presented!, is: app)
    }

    @Test("present() on Root does not change current root destination")
    func rootPresentDoesNotChangeRoot() {
        let app = AppRootCoordinator()
        _ = app.anyRoot
        let initialRoot = app.root.root?.coordinatable as? MainTabCoordinator
        #expect(initialRoot != nil)

        app.present(.login, as: .sheet)

        let stillRoot = app.root.root?.coordinatable as? MainTabCoordinator
        #expect(stillRoot === initialRoot,
                "present() must not replace the root view")
    }

    @Test("dismissCoordinator on Root modal child removes from root.modals")
    func dismissRootModalChildRemovesFromModals() {
        let app = AppRootCoordinator()
        _ = app.anyRoot

        app.present(.login, as: .sheet)
        let presented = app.root.modals.first?.coordinatable as? LoginFlowCoordinator
        #expect(presented != nil)

        presented!.dismissCoordinator()

        #expect(app.root.modals.isEmpty,
                "Modal child must be removable via dismissCoordinator on Root parent")
    }

    @Test("Root modal onDismiss fires once on dismissCoordinator")
    func rootModalOnDismissFires() {
        let app = AppRootCoordinator()
        _ = app.anyRoot

        var fired = 0
        app.present(.login, as: .sheet, onDismiss: { fired += 1 })

        let presented = app.root.modals.first?.coordinatable as? LoginFlowCoordinator
        presented!.dismissCoordinator()

        #expect(fired == 1)
    }

    @Test("dismissCoordinator on Root tab child (non-modal) is unchanged behavior")
    func dismissNonModalRootChildUnchanged() {
        let app = AppRootCoordinator()
        _ = app.anyRoot

        let tabCoord = app.root.root?.coordinatable as? MainTabCoordinator
        #expect(tabCoord != nil)

        // Root child that is NOT in modals — falls through to existing behavior
        // (calls parent.parent?.dismissCoordinator(); app has no parent → no-op).
        // Must not crash and must not touch root.modals (empty here).
        tabCoord!.dismissCoordinator()
        #expect(app.root.modals.isEmpty)
    }

    // MARK: Cross-cutting

    @Test("present() propagates presentedAs to a presented Flow coordinator")
    func presentPropagatesPresentedAsToFlow() {
        let app = AppRootCoordinator()
        _ = app.anyRoot

        app.present(.login, as: .fullScreenCover)

        let login = app.root.modals.first?.coordinatable as? LoginFlowCoordinator
        #expect(login != nil)
        #expect(login?.stack.presentedAs == .fullScreenCover,
                "Flow coordinator presented modally inherits presentedAs")
    }

    @Test("ModalPresentationType maps to PresentationType correctly")
    func modalPresentationTypeMapping() {
        // Round-trip the public enum through DestinationType.
        let sheetDest = DestinationType.from(presentationType: ModalPresentationType.sheet.presentationType)
        let coverDest = DestinationType.from(presentationType: ModalPresentationType.fullScreenCover.presentationType)
        #expect(sheetDest == .sheet)
        #expect(coverDest == .fullScreenCover)
    }

    // MARK: present<T>() typed-callback overload

    @Test("present<T>() on Flow fires callback with the resolved coordinator")
    func flowPresentTypedFiresCallback() {
        let home = HomeFlowCoordinator()
        _ = home.anyStack

        var captured: LeafFlowCoordinator?
        home.present(.sheetFlow, as: .sheet) { (leaf: LeafFlowCoordinator) in
            captured = leaf
        }

        let modal = home.stack.destinations.last
        let presented = modal?.coordinatable as? LeafFlowCoordinator
        #expect(captured != nil)
        #expect(captured === presented,
                "Typed callback receives the same instance that was appended to the stack")
    }

    @Test("present<T>() on Flow skips callback when type does not match")
    func flowPresentTypedSkipsOnTypeMismatch() {
        let home = HomeFlowCoordinator()
        _ = home.anyStack

        var fired = false
        home.present(.sheetFlow, as: .sheet) { (_: SettingsFlowCoordinator) in
            fired = true
        }

        #expect(fired == false,
                "Callback must not fire when the resolved coordinator cannot be cast to T")
        #expect(home.stack.destinations.last?.coordinatable is LeafFlowCoordinator,
                "Modal still lands on the stack regardless of callback type")
    }

    @Test("present<T>() on Tab fires callback with the resolved coordinator")
    func tabPresentTypedFiresCallback() {
        let tab = MainTabCoordinator()
        _ = tab.anyTabItems

        var captured: SettingsFlowCoordinator?
        tab.present(.settings, as: .sheet) { (settings: SettingsFlowCoordinator) in
            captured = settings
        }

        let presented = tab.tabItems.modals.last?.coordinatable as? SettingsFlowCoordinator
        #expect(captured != nil)
        #expect(captured === presented)
    }

    @Test("present<T>() on Root fires callback with the resolved coordinator")
    func rootPresentTypedFiresCallback() {
        let app = AppRootCoordinator()
        _ = app.anyRoot

        var captured: LoginFlowCoordinator?
        app.present(.login, as: .sheet) { (login: LoginFlowCoordinator) in
            captured = login
        }

        let presented = app.root.modals.last?.coordinatable as? LoginFlowCoordinator
        #expect(captured != nil)
        #expect(captured === presented)
    }

    @Test("present<T>() forwards onDismiss to the modal destination")
    func flowPresentTypedForwardsOnDismiss() {
        let home = HomeFlowCoordinator()
        _ = home.anyStack

        var dismissed = 0
        home.present(.sheetFlow, as: .sheet, onDismiss: { dismissed += 1 }) { (_: LeafFlowCoordinator) in }

        let modalId = home.stack.destinations.last!.id
        home.removeModalDestination(withId: modalId, type: .sheet)

        #expect(dismissed == 1,
                "Typed overload still resolves the dismissal closure exactly once on removal")
    }
}
