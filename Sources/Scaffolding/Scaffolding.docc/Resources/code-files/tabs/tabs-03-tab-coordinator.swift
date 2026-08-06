import SwiftUI
import Scaffolding

@Scaffoldable @Observable
final class AppCoordinator: @MainActor TabCoordinatable {
    var tabItems = TabItems<AppCoordinator>(tabs: [.planets, .favorites])

    // Each tab returns its own coordinator plus the label for the tab bar.
    func planets() -> (any Coordinatable, some View) {
        (PlanetsCoordinator(), Label("Planets", systemImage: "globe"))
    }

    func favorites() -> (any Coordinatable, some View) {
        (FavoritesCoordinator(), Label("Favorites", systemImage: "star"))
    }
}
