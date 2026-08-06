import SwiftUI
import Scaffolding

@Scaffoldable @Observable
final class FavoritesCoordinator: @MainActor FlowCoordinatable {
    var stack = FlowStack<FavoritesCoordinator>(root: .list)

    private(set) var favorites: [String] = []

    func list() -> some View { FavoritesView() }
    func detail(name: String) -> some View { DetailView(name: name) }

    func add(_ planet: String) {
        guard !favorites.contains(planet) else { return }
        favorites.append(planet)
    }
}
