//
//  TabSelectionTests.swift
//  ScaffoldingTests
//
//  Tests for the shouldSelect(tab:isReselection:) interception hook on
//  TabCoordinatable, driven through the TabView selection binding.
//

import Testing
import SwiftUI
@testable import Scaffolding

// MARK: - GuardedTabCoordinator

/// A tab coordinator that guards its `.settings` tab and records every
/// invocation of the selection hook.
@MainActor @Observable
private final class GuardedTabCoordinator: TabCoordinatable {
    var tabItems: TabItems<GuardedTabCoordinator>

    var allowSettings = true
    /// When the settings tab is vetoed, redirect the selection here.
    var settingsRedirect: Destinations.Meta? = nil

    var hookTabs: [Destinations.Meta] = []
    var hookReselections: [Bool] = []

    init(tabs: [Destinations] = [.home, .profile, .settings], selectedIndex: Int? = nil) {
        self.tabItems = TabItems<GuardedTabCoordinator>(tabs: tabs, selectedIndex: selectedIndex)
    }

    func home() -> some View { EmptyView() }
    func profile() -> some View { EmptyView() }
    func settings() -> some View { EmptyView() }

    func shouldSelect(tab: Destinations.Meta, isReselection: Bool) -> Bool {
        hookTabs.append(tab)
        hookReselections.append(isReselection)

        guard tab == .settings, !allowSettings else { return true }
        if let redirect = settingsRedirect {
            selectFirstTab(redirect)
        }
        return false
    }

    enum Destinations: Destinationable {
        typealias Owner = GuardedTabCoordinator
        case home
        case profile
        case settings

        enum Meta: DestinationMeta {
            case home
            case profile
            case settings
        }

        var meta: Meta {
            switch self {
            case .home: return .home
            case .profile: return .profile
            case .settings: return .settings
            }
        }

        func value(for instance: Owner) -> Destination {
            switch self {
            case .home:
                return Destination(instance.home(), meta: meta, parent: instance)
            case .profile:
                return Destination(instance.profile(), meta: meta, parent: instance)
            case .settings:
                return Destination(instance.settings(), meta: meta, parent: instance)
            }
        }
    }
}

// MARK: - Tests

@MainActor
@Suite("TabCoordinatable.shouldSelect")
struct TabSelectionInterceptTests {

    enum InvalidSelection: CaseIterable {
        case first, last, id, index
    }

    @Test("Invalid selections preserve initial and programmatic selection before and after setup",
          arguments: InvalidSelection.allCases, [false, true])
    func invalidSelections(selection: InvalidSelection, resolved: Bool) {
        for programmatic in [false, true] {
            let tabs = GuardedTabCoordinator(tabs: [.home, .profile], selectedIndex: programmatic ? 0 : 1)
            if resolved { _ = tabs.anyTabItems }
            if programmatic { tabs.selectFirstTab(.profile) }

            switch selection {
            case .first: tabs.selectFirstTab(.settings)
            case .last: tabs.selectLastTab(.settings)
            case .id: tabs.select(id: UUID())
            case .index: tabs.select(index: 42)
            }

            #expect(tabs.tabItems.isSetup == resolved)
            #expect(tabs.selectedTabIndex == 1)
            #expect(tabs.hookTabs.isEmpty)
        }
    }

    @Test("Valid pending selections retain first/last semantics without resolving tabs")
    func validPendingSelections() {
        let tabs = GuardedTabCoordinator(tabs: [.home, .profile, .home])
        tabs.selectFirstTab(.profile)
        tabs.selectLastTab(.home)
        #expect(!tabs.tabItems.isSetup)
        #expect(tabs.selectedTabIndex == 2)
    }

    @Test("Allowed UI selection switches the tab and consults the hook")
    func allowedSelection() {
        let tabs = GuardedTabCoordinator()
        _ = tabs.anyTabItems
        let profileId = tabs.tabItems.tabs[1].id

        tabs.selectedTabBinding.wrappedValue = profileId

        #expect(tabs.tabItems.selectedTab == profileId)
        #expect(tabs.hookTabs == [.profile])
        #expect(tabs.hookReselections == [false])
    }

    @Test("Rejected UI selection keeps the current tab")
    func rejectedSelection() {
        let tabs = GuardedTabCoordinator()
        _ = tabs.anyTabItems
        let homeId = tabs.tabItems.tabs[0].id
        let settingsId = tabs.tabItems.tabs[2].id
        tabs.allowSettings = false

        tabs.selectedTabBinding.wrappedValue = settingsId

        #expect(tabs.tabItems.selectedTab == homeId)
        #expect(tabs.hookTabs == [.settings])
        #expect(tabs.hookReselections == [false])
    }

    @Test("A redirect performed inside the hook is preserved")
    func redirectPreserved() {
        let tabs = GuardedTabCoordinator()
        _ = tabs.anyTabItems
        let profileId = tabs.tabItems.tabs[1].id
        let settingsId = tabs.tabItems.tabs[2].id
        tabs.allowSettings = false
        tabs.settingsRedirect = .profile

        tabs.selectedTabBinding.wrappedValue = settingsId

        #expect(tabs.tabItems.selectedTab == profileId)
    }

    @Test("Re-tapping the selected tab fires the hook with isReselection")
    func reselection() {
        let tabs = GuardedTabCoordinator()
        _ = tabs.anyTabItems
        let homeId = tabs.tabItems.tabs[0].id
        #expect(tabs.tabItems.selectedTab == homeId)

        tabs.selectedTabBinding.wrappedValue = homeId

        #expect(tabs.tabItems.selectedTab == homeId)
        #expect(tabs.hookTabs == [.home])
        #expect(tabs.hookReselections == [true])
    }

    @Test("Programmatic selection bypasses the hook")
    func programmaticBypass() {
        let tabs = GuardedTabCoordinator()
        _ = tabs.anyTabItems
        tabs.allowSettings = false

        tabs.selectFirstTab(.settings)

        #expect(tabs.hookTabs.isEmpty)
        #expect(tabs.tabItems.selectedTab == tabs.tabItems.tabs[2].id)
    }

    @Test("Coordinators without an override keep the default pass-through")
    func defaultImplementation() {
        let tabs = MainTabCoordinator()
        _ = tabs.anyTabItems
        let profileId = tabs.tabItems.tabs[1].id

        tabs.selectedTabBinding.wrappedValue = profileId

        #expect(tabs.tabItems.selectedTab == profileId)
    }
}
