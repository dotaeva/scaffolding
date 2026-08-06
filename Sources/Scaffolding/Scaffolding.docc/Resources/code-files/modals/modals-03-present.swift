import SwiftUI
import Scaffolding

@Scaffoldable @Observable
final class FavoritesCoordinator: @MainActor FlowCoordinatable {
    var stack = FlowStack<FavoritesCoordinator>(root: .list)

    private(set) var favorites: [String] = []

    func list() -> some View { FavoritesView() }
    func detail(name: String) -> some View { DetailView(name: name) }
    func picker() -> any Coordinatable { PlanetPickerCoordinator() }

    func remove(_ planet: String) {
        favorites.removeAll { $0 == planet }
    }

    // The presenter owns the chrome: detents, drag indicator, and whether
    // the user may swipe the sheet away. The presented view stays ignorant,
    // so the same route can look different elsewhere.
    func addPlanet() {
        present(.picker, as: .sheet(detents: [.medium, .large]), policy: .distinct)
    }
}
