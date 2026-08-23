import SwiftUI
import Scaffolding

// MARK: - Selection

extension WeatherSplitCoordinator {
    /// Sidebar taps land here. setDetail *replaces* the column (tearing
    /// down the previous flow), so re-selection is guarded on domain
    /// state — every location is the same `.forecast` case, and
    /// `.distinct` compares case identity only.
    func select(_ location: Location) {
        guard store.selectedLocationID != location.id || !isDetail(.forecast) else { return }
        store.selectedLocationID = location.id
        setDetail(.forecast(location: location))
        // Keep the optional middle column in step with the selection.
        if anySplitColumns.hasContentColumn {
            setContent(.hours(location: location))
        }
    }
}

// MARK: - Columns

extension WeatherSplitCoordinator {
    /// Toolbar toggle: installs the Hourly middle column (the container
    /// swaps to the three-column form) or drops it again.
    func toggleHourlyColumn() {
        if anySplitColumns.hasContentColumn {
            removeContent()
        } else if let id = store.selectedLocationID, let location = store.location(id: id) {
            setContent(.hours(location: location))
        }
    }

    var canShowHourlyColumn: Bool {
        store.selectedLocationID != nil || anySplitColumns.hasContentColumn
    }
}

// MARK: - Modals

extension WeatherSplitCoordinator {
    func showSettings() {
        present(.settings, as: .sheet, policy: .distinct)
    }

    /// present(awaiting:) suspends until the sub-flow is dismissed and
    /// returns what it passed to dismissCoordinator(returning:) — nil for
    /// a swipe-down or cancel.
    func addCity() {
        Task {
            guard let city = await present(.addLocation, awaiting: Location.self) else { return }
            store.add(city)
            select(city)
        }
    }
}
