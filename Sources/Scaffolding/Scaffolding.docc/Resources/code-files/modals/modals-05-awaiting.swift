import SwiftUI
import Scaffolding

@Scaffoldable @Observable
final class FavoritesCoordinator: @MainActor FlowCoordinatable {
    var stack = FlowStack<FavoritesCoordinator>(root: .list)

    private(set) var favorites: [String] = []

    func list() -> some View { FavoritesView() }
    func detail(name: String) -> some View { DetailView(name: name) }
    // No closure payload this time — the result comes back through the
    // awaited call, which also keeps this route Codable-friendly.
    func picker() -> any Coordinatable { PlanetPickerCoordinator() }

    func remove(_ planet: String) {
        favorites.removeAll { $0 == planet }
    }

    func addPlanet() async {
        // Suspends until the sheet closes. Any dismissal that is not
        // dismissCoordinator(returning:) — a swipe, dismissModal(), a plain
        // dismissCoordinator() — resumes with nil, so cancellation is free.
        guard let planet = await present(.picker, awaiting: String.self) else { return }
        favorites.append(planet)
    }
}
