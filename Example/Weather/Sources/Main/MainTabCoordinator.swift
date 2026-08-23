import SwiftUI
import Scaffolding

/// iPhone shell: native tab bar, one flow coordinator per tab. Covers all
/// three tab-tuple shapes — coordinator+label, coordinator+label+TabRole,
/// and view-only+label (the dynamic Radar tab).
@MainActor
@Observable
@Scaffoldable(codable: true)
final class MainTabCoordinator: @MainActor TabCoordinatable {
    var tabItems = TabItems<MainTabCoordinator>(tabs: [.weather, .locations, .settings])

    let store: WeatherStore

    init(store: WeatherStore) {
        self.store = store
        // Both helpers resolve the tabs on demand, so configuring from
        // init — before the first render — is fine.
        setBadge(store.alerts.count, for: .weather)
        setTabAccessibilityIdentifier("tab.weather", for: .weather)
        setTabAccessibilityIdentifier("tab.locations", for: .locations)
        setTabAccessibilityIdentifier("tab.settings", for: .settings)
    }

    // MARK: Routes

    func weather() -> (any Coordinatable, some View) {
        (ForecastCoordinator(location: store.primary, store: store),
         Label("Weather", systemImage: "cloud.sun.fill"))
    }

    // The three-element tuple adds a TabRole — Locations becomes the
    // system search tab.
    func locations() -> (any Coordinatable, some View, TabRole) {
        (LocationsCoordinator(store: store),
         Label("Locations", systemImage: "list.star"),
         .search)
    }

    func settings() -> (any Coordinatable, some View) {
        (SettingsCoordinator(store: store),
         Label("Settings", systemImage: "gearshape.fill"))
    }

    // View-only tab (no coordinator) — appended and removed at runtime by
    // the Settings toggle.
    func radar() -> (some View, some View) {
        (RadarScreen(),
         Label("Radar", systemImage: "dot.radiowaves.left.and.right"))
    }

    // Presented above the whole TabView when shouldSelect vetoes Radar.
    func alert() -> some View { SevereAlertSheet() }
}

// MARK: - Selection interception

extension MainTabCoordinator {
    // Fires for UI-driven selection only; selectFirstTab / select(index:) /
    // deep links bypass it. Returns Bool ⇒ never macro-tracked.
    func shouldSelect(tab: Destinations.Meta, isReselection: Bool) -> Bool {
        if isReselection {
            // Re-tap of the current tab pops its flow to the root. The
            // typed trailing closure hands over the tab's coordinator.
            switch tab {
            case .weather: selectFirstTab(.weather) { (c: ForecastCoordinator) in c.popToRoot() }
            case .locations: selectFirstTab(.locations) { (c: LocationsCoordinator) in c.popToRoot() }
            case .settings: selectFirstTab(.settings) { (c: SettingsCoordinator) in c.popToRoot() }
            default: break
            }
            return true // ignored for re-taps — there's no change to veto
        }
        if tab == .radar && store.hasUnacknowledgedAlert {
            // Keep the current tab; make the user read the warning first.
            present(.alert, as: .sheet(
                detents: [.medium],
                dragIndicator: .hidden,
                interactiveDismissDisabled: true
            ))
            return false
        }
        return true
    }
}
