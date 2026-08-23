import Testing
import Scaffolding
import ScaffoldingTesting
@testable import Weather

/// Whole-tree capture and replay — codable: true end to end, including
/// graceful degradation for subtrees that don't opt in.
@MainActor
@Suite("State restoration")
struct RestorationTests {

    @Test("a deep tab tree round-trips: root, selection, pushes")
    func tabTreeRoundTrips() throws {
        let app = AppCoordinator(layout: .tabs).activated()
        app.finishOnboarding()
        let tabs = app.descendant(ofType: MainTabCoordinator.self)
        let weather = tabs?.selectFirstTab(.weather, expecting: ForecastCoordinator.self)?.activated()
        weather?.open(weather!.days[2])
        tabs?.selectFirstTab(.settings)

        let data = try app.captureNavigationState()

        let restored = AppCoordinator(layout: .tabs).activated()
        try restored.restoreNavigationState(from: data)

        #expect(restored.isRoot(.main))
        #expect(restored.hierarchyContains(MainTabCoordinator.self, .settings, as: .tab(index: 2, isSelected: true)))
        #expect(restored.hierarchyContains(ForecastCoordinator.self, .day, as: .push))
    }

    @Test("a split tree round-trips its detail column")
    func splitTreeRoundTrips() throws {
        let app = AppCoordinator(layout: .split).activated()
        app.finishOnboarding()
        app.descendant(ofType: WeatherSplitCoordinator.self)?.select(.tokyo)

        let data = try app.captureNavigationState()

        let restored = AppCoordinator(layout: .split).activated()
        try restored.restoreNavigationState(from: data)

        #expect(restored.hierarchyContains(WeatherSplitCoordinator.self, .forecast, as: .column(.detail)))
        #expect(restored.descendant(ofType: ForecastCoordinator.self)?.location == .tokyo)
    }

    @Test("non-codable subtrees restore at their initial position")
    func degradation() async throws {
        let app = AppCoordinator(layout: .tabs).activated()
        app.finishOnboarding()
        let locations = app.descendant(ofType: MainTabCoordinator.self)?
            .selectFirstTab(.locations, expecting: LocationsCoordinator.self)?.activated()
        locations?.addCity()
        await waitUntil { locations?.isPresentingModal == true }
        // Push inside the (non-codable) sub-flow — this depth is lost.
        locations?.descendant(ofType: AddLocationCoordinator.self)?.activated()
            .select(Location.searchable[0])

        let data = try app.captureNavigationState()

        let restored = AppCoordinator(layout: .tabs).activated()
        try restored.restoreNavigationState(from: data)

        // The modal itself is a codable route on LocationsCoordinator, so
        // it is re-presented — but the sub-flow inside restores at its
        // search root, its internal push gone.
        let picker = restored.descendant(ofType: AddLocationCoordinator.self)?.activated()
        #expect(picker != nil)
        #expect(picker?.depth == 0)
    }
}
