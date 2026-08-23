import SwiftUI
import Observation

/// Domain state — everything that is *not* navigation.
///
/// Coordinators receive the store through their initializers and mutate
/// it; views read it from `@Environment(WeatherStore.self)` (injected once
/// at the app entry point). Navigation state stays on the coordinators.
@MainActor
@Observable
final class WeatherStore {
    /// The followed locations, shown by the Locations tab / split sidebar.
    private(set) var saved: [Location] = Location.defaults

    /// Chosen during onboarding; changeable from Settings.
    var units: Units = .celsius

    /// Whether the dynamic Radar tab is installed (iPhone layout).
    var radarTabEnabled = false

    /// Unacknowledged severe-weather warnings — drives the tab badge and
    /// the radar-tab guard.
    private(set) var alerts: [WeatherAlert] = [.sample]

    /// Which location the split sidebar shows in the detail column.
    /// Domain state, not navigation state: `setDetail` replaces the column,
    /// so re-selection is guarded here (see WeatherSplitCoordinator).
    var selectedLocationID: Location.ID?

    /// Whether onboarding has completed (drives the root swap).
    var isOnboarded = false

    /// The location the iPhone Weather tab opens with.
    var primary: Location { saved.first ?? .prague }

    var hasUnacknowledgedAlert: Bool { !alerts.isEmpty }

    func add(_ location: Location) {
        guard !saved.contains(location) else { return }
        saved.append(location)
    }

    func remove(_ location: Location) {
        saved.removeAll { $0 == location }
        if selectedLocationID == location.id {
            selectedLocationID = nil
        }
    }

    func acknowledgeAlerts() {
        alerts.removeAll()
    }

    func location(id: Location.ID) -> Location? {
        (saved + Location.searchable).first { $0.id == id }
    }
}
