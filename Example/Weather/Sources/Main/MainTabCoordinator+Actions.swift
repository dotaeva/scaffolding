import SwiftUI
import Scaffolding

// MARK: - Cross-tab actions

extension MainTabCoordinator {
    /// Deep-link leg: land on a location's forecast inside the Locations
    /// tab. Typed closures resolve each child as the route lands.
    func openLocation(_ location: Location) {
        selectFirstTab(.locations) { (locations: LocationsCoordinator) in
            locations.showForecast(for: location)
        }
    }

    /// Settings toggle → dynamic tab. Duplicates are allowed by the API,
    /// so guard with isInTabItems.
    func setRadarTab(enabled: Bool) {
        if enabled, !isInTabItems(.radar) {
            appendTab(.radar)
        } else if !enabled {
            removeFirstTab(.radar)
        }
    }

    /// Re-syncs the Weather tab badge after alerts change — the alert
    /// sheet can be presented by either shell coordinator or the forecast
    /// flow, so it clears the badge here and dismisses itself natively.
    func clearAlertBadge() {
        setBadge(store.alerts.count, for: .weather)   // 0 clears the badge
    }
}
