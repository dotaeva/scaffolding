import Testing
import Scaffolding
import ScaffoldingTesting
@testable import Weather

/// Child-coordinator pushes, view-only sheets with presenter-side
/// dismissal, and the value-returning add-city sub-flow.
@MainActor
@Suite("Locations flow")
struct LocationsFlowTests {

    @Test("opening a place pushes a whole child coordinator")
    func childCoordinatorPush() {
        let locations = LocationsCoordinator(store: WeatherStore()).activated()

        // expecting: hands the pushed child over at the moment it lands.
        let child = locations.route(to: .forecast(location: .tokyo), expecting: ForecastCoordinator.self)

        #expect(locations.hierarchyContains(LocationsCoordinator.self, .forecast, as: .push))
        #expect(child?.location == .tokyo)
    }

    @Test("present's onDismiss fires exactly once")
    func presentOnDismiss() {
        let locations = LocationsCoordinator(store: WeatherStore()).activated()
        var dismissals = 0
        locations.present(.preview(location: .prague), as: .sheet, onDismiss: { dismissals += 1 })

        locations.dismissModal()
        locations.dismissModal()   // nothing presented — safe no-op

        #expect(dismissals == 1)
    }

    @Test("quick look is a view-only sheet the presenter closes")
    func quickLookModal() {
        let locations = LocationsCoordinator(store: WeatherStore()).activated()

        locations.quickLook(.prague)
        locations.quickLook(.prague)     // .distinct — skipped

        #expect(locations.isPresentingModal)
        #expect(locations.count(of: .preview) == 1)

        locations.closeQuickLook()       // dismissModal()
        #expect(!locations.isPresentingModal)
        #expect(locations.depth == 0)    // pushes untouched
    }

    @Test("addCity awaits the sub-flow's returned value")
    func addCityReturnsValue() async {
        let store = WeatherStore()
        let locations = LocationsCoordinator(store: store).activated()
        let lisbon = Location.searchable[0]

        locations.addCity()
        await waitUntil { locations.isPresentingModal }

        // descendant(ofType:) — the only way to a child the code under
        // test presented itself.
        let picker = locations.descendant(ofType: AddLocationCoordinator.self)?.activated()
        picker?.select(lisbon)
        picker?.finish(with: lisbon)     // dismissCoordinator(returning:)

        await waitUntil { store.saved.contains(lisbon) }
        #expect(!locations.isPresentingModal)
        #expect(locations.isInStack(.forecast))   // continuation pushed it
    }

    @Test("cancelling the sub-flow resumes the presenter with nil")
    func addCityCancelled() async {
        let store = WeatherStore()
        let locations = LocationsCoordinator(store: store).activated()
        let savedBefore = store.saved

        locations.addCity()
        await waitUntil { locations.isPresentingModal }

        locations.descendant(ofType: AddLocationCoordinator.self)?.cancel()

        await waitUntil { !locations.isPresentingModal }
        #expect(store.saved == savedBefore)
        #expect(locations.depth == 0)
    }
}
