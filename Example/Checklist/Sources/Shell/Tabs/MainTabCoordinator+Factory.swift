import SwiftUI
import Scaffolding

// MARK: - Factory
// Where each route's screen is actually assembled: views get their
// ViewModels here, child coordinators get their dependencies. The
// route table stays in the class body because @Scaffoldable scans
// only the class declaration — a route in an extension is silently
// untracked — while these `make…` helpers are invisible to it, so
// they need no @ScaffoldingIgnored.

extension MainTabCoordinator {
    func makeToday() -> (any Coordinatable, some View) {
        (TodayCoordinator(store: store), Label("Today", systemImage: "calendar"))
    }

    func makeLists() -> (any Coordinatable, some View) {
        (ListsCoordinator(store: store), Label("Lists", systemImage: "list.bullet"))
    }

    /// The three-element tuple adds a `TabRole` — Search becomes the
    /// system search tab.
    func makeSearch() -> (any Coordinatable, some View, TabRole) {
        (SearchCoordinator(store: store), Label("Search", systemImage: "magnifyingglass"), .search)
    }

    /// The navigation playground, a first-class tab.
    func makePlayground() -> (any Coordinatable, some View) {
        (PlaygroundCoordinator(), Label("Playground", systemImage: "arrow.triangle.branch"))
    }

    func makeSettings() -> (any Coordinatable, some View) {
        (SettingsCoordinator(store: store), Label("Settings", systemImage: "gearshape"))
    }

    /// Added and removed at runtime from Settings.
    func makeStats() -> (any Coordinatable, some View) {
        (StatsCoordinator(store: store), Label("Stats", systemImage: "chart.bar.fill"))
    }

    /// Presented above the whole `TabView` when `shouldSelect` vetoes Stats.
    func makeStatsLocked() -> some View { StatsLockedSheet() }
}
