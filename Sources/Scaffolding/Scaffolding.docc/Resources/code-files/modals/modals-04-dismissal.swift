import SwiftUI
import Scaffolding

@Scaffoldable @Observable
final class FavoritesCoordinator: @MainActor FlowCoordinatable {
    var stack = FlowStack<FavoritesCoordinator>(root: .list)

    private(set) var favorites: [String] = []

    func list() -> some View { FavoritesView() }
    func detail(name: String) -> some View { DetailView(name: name) }
    func picker() -> any Coordinatable { PlanetPickerCoordinator() }
    func syncing() -> some View { SyncingOverlay() }

    func remove(_ planet: String) {
        favorites.removeAll { $0 == planet }
    }

    func addPlanet() {
        present(.picker, as: .sheet(detents: [.medium, .large]), policy: .distinct)
    }

    // A view-only modal the user cannot close — only the presenter can, and
    // dismissModal() is the way. pop() would remove a pushed screen instead;
    // dismissModal() never touches the push stack and no-ops when nothing
    // is presented.
    func sync() async {
        present(.syncing, as: .sheet(detents: [.medium], interactiveDismissDisabled: true))
        await FavoritesService.sync()
        dismissModal()
    }
}
