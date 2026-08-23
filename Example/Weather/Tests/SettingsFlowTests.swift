import Testing
import Scaffolding
import ScaffoldingTesting
@testable import Weather

/// Awaiting pickers, presenter-closed overlays, and dismissAllModals.
@MainActor
@Suite("Settings flow")
struct SettingsFlowTests {

    @Test("the units picker returns its value through awaiting:")
    func unitsPickerReturns() async {
        let store = WeatherStore()
        let settings = SettingsCoordinator(store: store).activated()

        settings.changeUnits()
        await waitUntil { settings.isPresentingModal }

        settings.descendant(ofType: UnitsPickerCoordinator.self)?.pick(.fahrenheit)

        await waitUntil { store.units == .fahrenheit }
        #expect(!settings.isPresentingModal)
    }

    @Test("cancelling the picker leaves the units untouched")
    func unitsPickerCancelled() async {
        let store = WeatherStore()
        let settings = SettingsCoordinator(store: store).activated()

        settings.changeUnits()
        await waitUntil { settings.isPresentingModal }

        settings.descendant(ofType: UnitsPickerCoordinator.self)?.cancel()

        await waitUntil { !settings.isPresentingModal }
        #expect(store.units == .celsius)
    }

    @Test("the refresh overlay is presenter-guarded against stacking")
    func refreshOverlay() {
        let settings = SettingsCoordinator(store: WeatherStore()).activated()

        settings.refreshAll()
        settings.refreshAll()              // guard: already presenting

        #expect(settings.count(of: .refreshing) == 1)
    }

    @Test("dismissAllModals clears everything but the stack")
    func dismissAll() {
        let settings = SettingsCoordinator(store: WeatherStore()).activated()
        settings.showAbout()
        settings.refreshAll()

        settings.closeAllModals()

        #expect(!settings.isPresentingModal)
        #expect(settings.depth == 1)       // the pushed About stays
    }

    @Test("pushed screens stack and the tree dump is reachable")
    func pushes() {
        let settings = SettingsCoordinator(store: WeatherStore()).activated()

        settings.showAbout()
        settings.showTree()

        #expect(settings.depth == 2)
        #expect(settings.topDestination == .tree)
    }
}
