import SwiftUI
import Scaffolding

/// The Locations tab (iPhone): saved places, quick-look sheets, and the
/// add-city sub-flow. Pushing a place's forecast pushes a whole *child
/// coordinator* onto this stack — the existential return is what the
/// macro tracks.
@MainActor
@Observable
@Scaffoldable(codable: true)
final class LocationsCoordinator: @MainActor FlowCoordinatable {
    var stack = FlowStack<LocationsCoordinator>(root: .list)

    let store: WeatherStore

    init(store: WeatherStore) {
        self.store = store
    }

    // MARK: Routes

    func list() -> some View { LocationsScreen() }

    /// Child coordinator as a pushed destination — its pushes continue on
    /// this flow's NavigationStack; no nesting happens.
    func forecast(location: Location) -> any Coordinatable {
        ForecastCoordinator(location: location, store: store)
    }

    /// View-only modal: a single screen stays a plain `some View` route —
    /// no sub-flow, no child coordinator.
    func preview(location: Location) -> some View {
        LocationPreviewSheet(location: location)
    }

    /// Multi-step modal that hands back a value.
    func addLocation() -> any Coordinatable { AddLocationCoordinator() }
}

// MARK: - Actions

extension LocationsCoordinator {
    func showForecast(for location: Location) {
        route(to: .forecast(location: location), policy: .distinct)
    }

    /// The presenter decides the chrome: the same preview could be a
    /// full-height sheet elsewhere without the view knowing.
    func quickLook(_ location: Location) {
        present(.preview(location: location), as: .sheet(detents: [.medium]), policy: .distinct)
    }

    /// Presenter-side close for the view-only sheet — there is no child
    /// coordinator in it to call dismissCoordinator().
    func closeQuickLook() {
        dismissModal()
    }

    /// present(awaiting:) — suspends until the sub-flow returns a city via
    /// dismissCoordinator(returning:); cancel and swipe-down resume nil.
    func addCity() {
        Task {
            guard let city = await present(.addLocation, awaiting: Location.self) else { return }
            store.add(city)
            showForecast(for: city)
        }
    }
}
