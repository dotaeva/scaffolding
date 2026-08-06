import SwiftUI
import Scaffolding

@Scaffoldable @Observable
final class AppCoordinator: @MainActor TabCoordinatable {
    var tabItems = TabItems<AppCoordinator>(tabs: [.planets, .favorites, .search])

    func planets() -> (any Coordinatable, some View) {
        (PlanetsCoordinator(), Label("Planets", systemImage: "globe"))
    }

    func favorites() -> (any Coordinatable, some View) {
        (FavoritesCoordinator(), Label("Favorites", systemImage: "star"))
    }

    // A third tuple element adopts a system TabRole — .search gets the
    // platform's search-tab treatment.
    func search() -> (any Coordinatable, some View, TabRole) {
        (SearchCoordinator(), Label("Search", systemImage: "magnifyingglass"), .search)
    }
}
