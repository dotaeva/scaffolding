import SwiftUI
import Scaffolding

/// iPhone shell: the native tab bar, one flow coordinator per tab.
///
/// Covers all three tab shapes the macro tracks — coordinator + label,
/// coordinator + label + `TabRole`, and view-only + label (the dynamic
/// Stats tab).
@MainActor
@Observable
@Scaffoldable(codable: true)
final class MainTabCoordinator: @MainActor TabCoordinatable {
    var tabItems = TabItems<MainTabCoordinator>(
        tabs: [.today, .lists, .search, .playground, .settings]
    )

    let store: TodoStore

    init(store: TodoStore) {
        self.store = store
        refreshBadge()
        setTabAccessibilityIdentifier("tab.today", for: .today)
        setTabAccessibilityIdentifier("tab.lists", for: .lists)
        setTabAccessibilityIdentifier("tab.search", for: .search)
        setTabAccessibilityIdentifier("tab.playground", for: .playground)
        setTabAccessibilityIdentifier("tab.settings", for: .settings)
    }

    // MARK: Routes

    func today() -> (any Coordinatable, some View) {
        (TodayCoordinator(store: store), Label("Today", systemImage: "calendar"))
    }

    func lists() -> (any Coordinatable, some View) {
        (ListsCoordinator(store: store), Label("Lists", systemImage: "list.bullet"))
    }

    /// The three-element tuple adds a `TabRole` — Search becomes the
    /// system search tab.
    func search() -> (any Coordinatable, some View, TabRole) {
        (SearchCoordinator(store: store), Label("Search", systemImage: "magnifyingglass"), .search)
    }

    /// The navigation playground, a first-class tab.
    func playground() -> (any Coordinatable, some View) {
        (PlaygroundCoordinator(), Label("Playground", systemImage: "arrow.triangle.branch"))
    }

    func settings() -> (any Coordinatable, some View) {
        (SettingsCoordinator(store: store), Label("Settings", systemImage: "gearshape"))
    }

    /// Added and removed at runtime from Settings.
    func stats() -> (any Coordinatable, some View) {
        (StatsCoordinator(store: store), Label("Stats", systemImage: "chart.bar.fill"))
    }

    /// Presented above the whole `TabView` when `shouldSelect` vetoes Stats.
    func statsLocked() -> some View { StatsLockedSheet() }
}

// MARK: - Selection interception

extension MainTabCoordinator {
    /// Fires for UI-driven selection only — `selectFirstTab`,
    /// `select(index:)`, and deep links bypass it. Returns `Bool`, so the
    /// macro never tracks it.
    func shouldSelect(tab: Destinations.Meta, isReselection: Bool) -> Bool {
        if isReselection {
            // Re-tap of the current tab pops its flow to the root; the
            // typed closure hands over that tab's child coordinator.
            switch tab {
            case .today: selectFirstTab(.today) { (c: TodayCoordinator) in c.popToRoot() }
            case .lists: selectFirstTab(.lists) { (c: ListsCoordinator) in c.popToRoot() }
            case .search: selectFirstTab(.search) { (c: SearchCoordinator) in c.popToRoot() }
            case .playground: selectFirstTab(.playground) { (c: PlaygroundCoordinator) in c.popToRoot() }
            case .settings: selectFirstTab(.settings) { (c: SettingsCoordinator) in c.popToRoot() }
            default: break
            }
            return true // ignored for re-taps — there is no change to veto
        }
        if tab == .stats && store.completedCount == 0 {
            // Keep the current tab and explain why instead of switching.
            present(.statsLocked, as: .sheet(detents: [.medium]))
            return false
        }
        return true
    }
}
