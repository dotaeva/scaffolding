import SwiftUI
import Scaffolding

// This flow keeps a closure route, so it cannot opt into codable: — and
// that is fine. Its subtree is recorded without internal state and comes
// back at its initial position while the rest of the tree restores fully.
//
// Only calling captureNavigationState() *directly on* a non-codable
// coordinator throws NavigationStateError.unsupported.
@Scaffoldable @Observable
final class FavoritesCoordinator: @MainActor FlowCoordinatable {
    var stack = FlowStack<FavoritesCoordinator>(root: .list)

    private(set) var favorites: [String] = []

    func list() -> some View { FavoritesView() }
    func detail(name: String) -> some View { DetailView(name: name) }
    func picker(onPick: @escaping @MainActor (String) -> Void) -> any Coordinatable {
        PlanetPickerCoordinator(onPick: onPick)
    }
}
