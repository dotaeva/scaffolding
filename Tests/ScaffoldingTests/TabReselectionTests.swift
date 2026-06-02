//
//  TabReselectionTests.swift
//  ScaffoldingTests
//
//  Tests for tab re-selection detection via `tabReselected(_:)`.
//  Re-selection fires only through the selection binding (a user tap),
//  never through programmatic selection.
//

import Testing
import SwiftUI
@testable import Scaffolding

// MARK: - Tab Re-selection

@MainActor
@Suite("Tab re-selection")
struct TabReselectionTests {

    @Test("Re-selecting the current tab through the binding invokes tabReselected")
    func bindingReselectInvokesCallback() {
        guard #available(iOS 18, macOS 15, *) else { return }
        let tab = ReselectTrackingTabCoordinator()
        _ = tab.anyTabItems

        let selected = tab.tabItems.selectedTab
        #expect(selected != nil)

        tab.selectedTabBinding.wrappedValue = selected

        #expect(tab.reselectedTabs.count == 1)
        #expect(tab.reselectedTabs.first?.id == selected)
        #expect(tab.reselectedTabs.first?.meta as? ReselectTrackingTabCoordinator.Destinations.Meta == .home)
        #expect(tab.tabItems.selectedTab == selected)
    }

    @Test("Re-selecting twice invokes tabReselected each time")
    func bindingReselectInvokesCallbackEachTime() {
        guard #available(iOS 18, macOS 15, *) else { return }
        let tab = ReselectTrackingTabCoordinator()
        _ = tab.anyTabItems

        let selected = tab.tabItems.selectedTab
        tab.selectedTabBinding.wrappedValue = selected
        tab.selectedTabBinding.wrappedValue = selected

        #expect(tab.reselectedTabs.count == 2)
    }

    @Test("Selecting a different tab through the binding does not invoke tabReselected")
    func bindingSwitchDoesNotInvokeCallback() {
        guard #available(iOS 18, macOS 15, *) else { return }
        let tab = ReselectTrackingTabCoordinator()
        _ = tab.anyTabItems

        let second = tab.tabItems.tabs[1].id
        tab.selectedTabBinding.wrappedValue = second

        #expect(tab.reselectedTabs.isEmpty)
        #expect(tab.tabItems.selectedTab == second)
    }

    @Test("Programmatic selection of the current tab does not invoke tabReselected")
    func programmaticReselectDoesNotInvokeCallback() {
        guard #available(iOS 18, macOS 15, *) else { return }
        let tab = ReselectTrackingTabCoordinator()
        _ = tab.anyTabItems

        // .home is the first tab and selected by default.
        tab.selectFirstTab(.home)

        #expect(tab.reselectedTabs.isEmpty)
        #expect(tab.tabItems.selectedTab == tab.tabItems.tabs.first?.id)
    }

    @Test("Clearing selection through the binding does not invoke tabReselected")
    func nilSelectionDoesNotInvokeCallback() {
        guard #available(iOS 18, macOS 15, *) else { return }
        let tab = ReselectTrackingTabCoordinator()
        _ = tab.anyTabItems

        tab.selectedTabBinding.wrappedValue = nil

        #expect(tab.reselectedTabs.isEmpty)
        #expect(tab.tabItems.selectedTab == nil)
    }
}
