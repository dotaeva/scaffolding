//
//  TabAccessibilityIdentifierTests.swift
//  ScaffoldingTests
//
//  Tests for tab accessibility identifier state on TabItems.
//

import Testing
import SwiftUI
@testable import Scaffolding

// MARK: - Tab Accessibility Identifiers

@MainActor
@Suite("Tab accessibility identifiers")
struct TabAccessibilityIdentifierTests {

    @Test("Setting identifier metadata stores it without changing selection")
    func storesIdentifierWithoutChangingSelection() {
        guard #available(iOS 18, macOS 15, *) else { return }
        let tab = MainTabCoordinator()
        _ = tab.anyTabItems

        let selected = tab.tabItems.selectedTab
        let tabIDs = tab.tabItems.tabs.map(\.id)
        let homeID = tabIDs[0]
        let value = TabBarAccessibilityIdentifier(identifier: "home.tab", matchingLabels: ["Home"])

        tab.tabItems.setTabBarAccessibilityIdentifier(value, for: homeID)

        #expect(tab.tabItems.tabBarAccessibilityIdentifier(for: homeID) == value)
        #expect(tab.tabItems.selectedTab == selected)
        #expect(tab.tabItems.tabs.map(\.id) == tabIDs)
    }

    @Test("Updating identifier metadata replaces the stored value")
    func updateReplacesIdentifier() {
        guard #available(iOS 18, macOS 15, *) else { return }
        let tab = MainTabCoordinator()
        _ = tab.anyTabItems

        let homeID = tab.tabItems.tabs[0].id
        tab.tabItems.setTabBarAccessibilityIdentifier(
            .init(identifier: "home.old", matchingLabels: ["Home"]),
            for: homeID
        )
        let updated = TabBarAccessibilityIdentifier(identifier: "home.new", matchingLabels: ["Start"])

        tab.tabItems.setTabBarAccessibilityIdentifier(updated, for: homeID)

        #expect(tab.tabItems.tabBarAccessibilityIdentifier(for: homeID) == updated)
    }

    @Test("Nil clears existing identifier metadata")
    func nilClearsIdentifier() {
        guard #available(iOS 18, macOS 15, *) else { return }
        let tab = MainTabCoordinator()
        _ = tab.anyTabItems

        let selected = tab.tabItems.selectedTab
        let tabIDs = tab.tabItems.tabs.map(\.id)
        let homeID = tab.tabItems.tabs[0].id
        tab.tabItems.setTabBarAccessibilityIdentifier(
            .init(identifier: "home.tab", matchingLabels: ["Home"]),
            for: homeID
        )

        tab.tabItems.setTabBarAccessibilityIdentifier(nil, for: homeID)

        #expect(tab.tabItems.tabBarAccessibilityIdentifier(for: homeID) == nil)
        #expect(tab.tabItems.selectedTab == selected)
        #expect(tab.tabItems.tabs.map(\.id) == tabIDs)
    }

    @Test("Identifier metadata is independent per tab id")
    func identifiersAreIndependentPerTabID() {
        guard #available(iOS 18, macOS 15, *) else { return }
        let tab = MainTabCoordinator()
        _ = tab.anyTabItems

        let homeID = tab.tabItems.tabs[0].id
        let profileID = tab.tabItems.tabs[1].id
        let profileValue = TabBarAccessibilityIdentifier(identifier: "profile.tab", matchingLabels: ["Profile"])

        tab.tabItems.setTabBarAccessibilityIdentifier(
            .init(identifier: "home.tab", matchingLabels: ["Home"]),
            for: homeID
        )
        tab.tabItems.setTabBarAccessibilityIdentifier(profileValue, for: profileID)
        tab.tabItems.setTabBarAccessibilityIdentifier(nil, for: homeID)

        #expect(tab.tabItems.tabBarAccessibilityIdentifier(for: homeID) == nil)
        #expect(tab.tabItems.tabBarAccessibilityIdentifier(for: profileID) == profileValue)
    }

    @Test("Setting identifier metadata by meta after setup preserves tabs and selection")
    func metaIdentifierAfterSetupPreservesTabsAndSelection() {
        guard #available(iOS 18, macOS 15, *) else { return }
        let tab = MainTabCoordinator()
        _ = tab.anyTabItems

        let selected = tab.tabItems.selectedTab
        let tabIDs = tab.tabItems.tabs.map(\.id)
        let profileID = tabIDs[1]
        let value = TabBarAccessibilityIdentifier(identifier: "profile.tab", matchingLabels: ["Profile"])

        tab.tabItems.setTabBarAccessibilityIdentifier(value, forFirst: .profile)

        #expect(tab.tabItems.tabBarAccessibilityIdentifier(for: profileID) == value)
        #expect(tab.tabItems.selectedTab == selected)
        #expect(tab.tabItems.tabs.map(\.id) == tabIDs)
    }

    @Test("Setting identifier metadata by meta before setup applies after setup")
    func metaIdentifierBeforeSetupAppliesAfterSetup() {
        guard #available(iOS 18, macOS 15, *) else { return }
        let tab = MainTabCoordinator()
        let value = TabBarAccessibilityIdentifier(identifier: "profile.tab", matchingLabels: ["Profile"])

        tab.tabItems.setTabBarAccessibilityIdentifier(value, forFirst: .profile)
        _ = tab.anyTabItems

        let profileID = tab.tabItems.tabs[1].id
        #expect(tab.tabItems.tabBarAccessibilityIdentifier(for: profileID) == value)
    }

    @Test("Clearing identifier metadata by meta before setup wins over pending setup")
    func pendingMetaIdentifierClearBeforeSetupWins() {
        guard #available(iOS 18, macOS 15, *) else { return }
        let tab = MainTabCoordinator()
        let value = TabBarAccessibilityIdentifier(identifier: "profile.tab", matchingLabels: ["Profile"])

        tab.tabItems.setTabBarAccessibilityIdentifier(value, forFirst: .profile)
        tab.tabItems.setTabBarAccessibilityIdentifier(nil, forFirst: .profile)
        _ = tab.anyTabItems

        let profileID = tab.tabItems.tabs[1].id
        #expect(tab.tabItems.tabBarAccessibilityIdentifier(for: profileID) == nil)
    }

    @Test("Identifier matching trims labels and allows localized case-insensitive containment both directions")
    func identifierMatchingIsTolerantOfRenderedLabelDifferences() {
        guard #available(iOS 18, macOS 15, *) else { return }
        let identifier = TabBarAccessibilityIdentifier(identifier: "profile.tab", matchingLabels: [" profile "])

        #expect(identifier.matches(renderedLabel: "PROFILE 3"))
        #expect(identifier.matches(renderedLabel: "  prof  "))
        #expect(!identifier.matches(renderedLabel: "Home"))
    }

    @Test("AnyTabItems exposes identifier metadata getter")
    func anyTabItemsGetterReturnsIdentifier() {
        guard #available(iOS 18, macOS 15, *) else { return }
        let tab = MainTabCoordinator()
        let anyTabItems = tab.anyTabItems
        let homeID = tab.tabItems.tabs[0].id
        let value = TabBarAccessibilityIdentifier(identifier: "home.tab", matchingLabels: ["Home"])

        tab.tabItems.setTabBarAccessibilityIdentifier(value, for: homeID)

        #expect(anyTabItems.tabBarAccessibilityIdentifier(for: homeID) == value)
    }

    @Test("AnyTabItems conformers without identifier storage default to nil")
    func anyTabItemsDefaultIdentifierGetterReturnsNil() {
        guard #available(iOS 18, macOS 15, *) else { return }
        let tabItems = LegacyAnyTabItemsConformer()
        let tabID = UUID()

        #expect(tabItems.tabBarAccessibilityIdentifier(for: tabID) == nil)
    }

    @Test("Empty matching labels are stored for renderer decisions")
    func emptyMatchingLabelsAreStored() {
        guard #available(iOS 18, macOS 15, *) else { return }
        let tab = MainTabCoordinator()
        _ = tab.anyTabItems
        let homeID = tab.tabItems.tabs[0].id
        let value = TabBarAccessibilityIdentifier(identifier: "home.tab", matchingLabels: [])

        tab.tabItems.setTabBarAccessibilityIdentifier(value, for: homeID)

        #expect(tab.tabItems.tabBarAccessibilityIdentifier(for: homeID) == value)
    }
}

@available(iOS 18, macOS 15, *)
@MainActor
private final class LegacyAnyTabItemsConformer: AnyTabItems {
    typealias Coordinator = MainTabCoordinator

    var parent: (any Coordinatable)?
    var hasLayerNavigationCoordinator = false
    var isSetup = false
    var tabs: [Destination] = []
    var selectedTab: UUID?
    var tabBarVisibility: Visibility = .automatic
    var presentedAs: PresentationType?
    var modals: [Destination] = []

    func setParent(_ parent: any Coordinatable) {
        self.parent = parent
    }

    func setup(for coordinator: MainTabCoordinator) {
        isSetup = true
    }

    func badge(for tabID: Destination.ID) -> Int? {
        nil
    }
}
