import SwiftUI
import Scaffolding

// A single-screen modal with no navigation of its own is not a coordinator
// concern. Keep it native: local @State, native .sheet(item:).
struct FavoritesView: View {
    @Environment(FavoritesCoordinator.self) private var coordinator

    // .sheet(item:) needs an Identifiable value; a one-line wrapper does it.
    private struct Removal: Identifiable { let id: String }
    @State private var pendingRemoval: Removal?

    var body: some View {
        List(coordinator.favorites, id: \.self) { planet in
            Button(planet) { pendingRemoval = Removal(id: planet) }
        }
        .sheet(item: $pendingRemoval) { removal in
            ConfirmRemovalSheet(planet: removal.id) {
                coordinator.remove(removal.id)
            }
        }
    }
}
