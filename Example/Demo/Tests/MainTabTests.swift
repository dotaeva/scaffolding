import Testing
import Scaffolding
import ScaffoldingTesting
@testable import Demo

/// Tab selection, the `shouldSelect` guard, badges, and dynamic tabs.
@MainActor
@Suite("Main tabs")
struct MainTabTests {

    @Test("tabs come up on the configured selection")
    func initialSelection() {
        let tabs = MainTabCoordinator().activated()

        #expect(tabs.selectedIndex == 0)
        #expect(tabs.barItems.map(\.label) == ["Home", "Cards", "Invest", "Profile"])
    }

    @Test("shouldSelect vetoes the locked invest tab and shows the gate")
    func vetoedTabPresentsDisclaimer() {
        let tabs = MainTabCoordinator().activated()

        // The hook is a plain method — call it the way the tab bar does.
        let allowed = tabs.shouldSelect(tab: .invest, isReselection: false)

        #expect(!allowed)
        #expect(tabs.isPresentingModal)
        #expect(tabs.selectedIndex == 0)   // selection never moved
    }

    @Test("accepting the disclaimer unlocks the tab and selects it")
    func acceptingDisclaimerSelectsInvest() {
        let tabs = MainTabCoordinator().activated()
        _ = tabs.shouldSelect(tab: .invest, isReselection: false)

        tabs.acceptInvestDisclaimer()

        #expect(tabs.investUnlocked)
        #expect(!tabs.isPresentingModal)
        #expect(tabs.selectedIndex == 2)
        #expect(tabs.shouldSelect(tab: .invest, isReselection: false))
    }

    @Test("a bar tap on the locked tab is vetoed, an unlocked one lands")
    func barTapsGoThroughTheHook() {
        let tabs = MainTabCoordinator().activated()

        tabs.barTapped(2)                  // invest, still locked
        #expect(tabs.selectedIndex == 0)

        tabs.investUnlocked = true
        tabs.barTapped(2)
        #expect(tabs.selectedIndex == 2)
    }

    @Test("re-tapping the selected tab pops its flow to the root")
    func reselectionPopsToRoot() {
        let tabs = MainTabCoordinator().activated()
        // Typed handle on the tab's child flow, without rendering a thing.
        let home = tabs.selectFirstTab(.home, expecting: HomeCoordinator.self)
        home?.open(Transaction.samples[0])
        #expect(home?.depth == 1)

        _ = tabs.shouldSelect(tab: .home, isReselection: true)

        #expect(home?.depth == 0)
        #expect(tabs.selectedIndex == 0)
    }

    @Test("badges are set numerically and read back as text")
    func badges() {
        let tabs = MainTabCoordinator().activated()

        tabs.setBadge(2, for: .invest)
        #expect(tabs.badge(for: .invest) == "2")
        #expect(tabs.barItems.first { $0.label == "Invest" }?.badge == "2")

        tabs.setBadge(0, for: .invest)      // 0 clears, like SwiftUI's badge(_:)
        #expect(tabs.badge(for: .invest) == nil)
    }

    @Test("tabs can be added and removed at runtime")
    func dynamicTabs() {
        let tabs = MainTabCoordinator().activated()
        #expect(!tabs.isInTabItems(.promo))

        tabs.appendTab(.promo)
        #expect(tabs.isInTabItems(.promo))
        #expect(tabs.barItems.count == 5)

        tabs.removeFirstTab(.promo)
        #expect(!tabs.isInTabItems(.promo))
        #expect(tabs.barItems.count == 4)
    }

    @Test("hiding the native bar is what turns the glass bar on")
    func tabBarVisibilityDrivesTheChrome() {
        let tabs = MainTabCoordinator().activated()
        #expect(tabs.showsGlassBar)

        tabs.setTabBarVisibility(.visible)

        #expect(!tabs.showsGlassBar)
    }

    @Test("each tab owns an independent stack")
    func tabsDoNotShareStacks() {
        let tabs = MainTabCoordinator().activated()
        let home = tabs.selectFirstTab(.home, expecting: HomeCoordinator.self)
        let profile = tabs.selectFirstTab(.profile, expecting: ProfileCoordinator.self)

        home?.open(Transaction.samples[0])
        profile?.openDeveloper()

        #expect(home?.depth == 1)
        #expect(profile?.depth == 1)
        #expect(home?.topDestination == .transaction)
        #expect(profile?.topDestination == .developer)
    }
}
