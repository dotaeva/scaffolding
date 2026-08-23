import Testing
import Scaffolding
import ScaffoldingTesting
@testable import Weather

/// The iPhone shell: selection, interception, dynamic tabs, badges, and
/// accessibility identifiers.
@MainActor
@Suite("Main tabs")
struct MainTabTests {
    private func makeTabs(store: WeatherStore = WeatherStore()) -> MainTabCoordinator {
        MainTabCoordinator(store: store).activated()
    }

    @Test("selection APIs move the selected tab")
    func selection() {
        let tabs = makeTabs()
        #expect(tabs.hierarchyContains(MainTabCoordinator.self, .weather, as: .tab(index: 0, isSelected: true)))

        tabs.selectFirstTab(.settings)
        #expect(tabs.hierarchyContains(MainTabCoordinator.self, .settings, as: .tab(index: 2, isSelected: true)))
        if let first = tabs.tabItems.tabs.first?.id {
            tabs.select(id: first)
        }
        #expect(tabs.hierarchyContains(MainTabCoordinator.self, .weather, as: .tab(index: 0, isSelected: true)))
    }

    @Test("re-tapping the selected tab pops its flow to the root")
    func reselectionPops() {
        let tabs = makeTabs()
        let weather = tabs.selectFirstTab(.weather, expecting: ForecastCoordinator.self)?.activated()
        weather?.open(weather!.days[1])
        #expect(weather?.depth == 1)

        _ = tabs.shouldSelect(tab: .weather, isReselection: true)

        #expect(weather?.depth == 0)
    }

    @Test("the radar tab is vetoed while an alert is unacknowledged")
    func radarGuard() {
        let store = WeatherStore()
        let tabs = makeTabs(store: store)
        tabs.setRadarTab(enabled: true)
        #expect(!tabs.shouldSelect(tab: .radar, isReselection: false))
        #expect(tabs.isPresentingModal)            // the warning sheet
        store.acknowledgeAlerts()                  // what Acknowledge does
        tabs.dismissModal()
        #expect(tabs.shouldSelect(tab: .radar, isReselection: false))
    }

    @Test("the radar tab is appended and removed dynamically")
    func dynamicRadarTab() {
        let tabs = makeTabs()
        #expect(!tabs.isInTabItems(.radar))

        tabs.setRadarTab(enabled: true)
        tabs.setRadarTab(enabled: true)            // guarded — no duplicate
        #expect(tabs.tabItems.tabs.count == 4)
        tabs.setRadarTab(enabled: false)
        #expect(!tabs.isInTabItems(.radar))
    }

    @Test("insert, last-selection, and setTabs round out the dynamic API")
    func dynamicTabAPI() {
        let tabs = makeTabs()
        tabs.insertTab(.radar, at: 1)
        tabs.appendTab(.radar)
        tabs.selectLastTab(.radar)
        #expect(tabs.hierarchyContains(MainTabCoordinator.self, .radar, as: .tab(index: 4, isSelected: true)))

        tabs.removeLastTab(.radar)
        tabs.select(index: 0)
        #expect(tabs.hierarchyContains(MainTabCoordinator.self, .weather, as: .tab(index: 0, isSelected: true)))

        tabs.setTabs([.weather, .locations, .settings])
        #expect(tabs.tabItems.tabs.count == 3)
        #expect(!tabs.isInTabItems(.radar))
    }

    @Test("the native bar can be hidden and shown")
    func barVisibility() {
        let tabs = makeTabs()
        tabs.setTabBarVisibility(.hidden)
        #expect(tabs.tabItems.tabBarVisibility == .hidden)
    }

    @Test("badges and accessibility identifiers are set from init")
    func badgesAndIdentifiers() {
        let store = WeatherStore()
        let tabs = makeTabs(store: store)

        #expect(tabs.badge(for: .weather) == "1")  // one sample alert
        #expect(tabs.tabAccessibilityIdentifier(for: .weather) == "tab.weather")

        store.acknowledgeAlerts()
        tabs.clearAlertBadge()
        #expect(tabs.badge(for: .weather) == nil)  // 0 clears
    }
}
