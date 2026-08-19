import SwiftUI
import Scaffolding

@Scaffoldable @Observable
final class AppCoordinator: @MainActor TabCoordinatable {
    var tabItems = TabItems<AppCoordinator>(tabs: [.planets, .favorites, .search])

    init() {
        // Identifiers belong on the coordinator, not the label view: only
        // the tab-bar item carries them, and they stay stable while the
        // visible label gets localized.
        setTabAccessibilityIdentifier("tab.planets", for: .planets)
        setTabAccessibilityIdentifier("tab.favorites", for: .favorites)
        setTabAccessibilityIdentifier("tab.search", for: .search)
    }

    func planets() -> (any Coordinatable, some View) {
        (PlanetsCoordinator(), Label("Planets", systemImage: "globe"))
    }

    func favorites() -> (any Coordinatable, some View) {
        (FavoritesCoordinator(), Label("Favorites", systemImage: "star"))
    }

    func search() -> (any Coordinatable, some View, TabRole) {
        (SearchCoordinator(), Label("Search", systemImage: "magnifyingglass"), .search)
    }
}
