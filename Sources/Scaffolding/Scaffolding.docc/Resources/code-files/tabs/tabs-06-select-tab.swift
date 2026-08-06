import SwiftUI
import Scaffolding

struct DetailView: View {
    // The nearest coordinator…
    @Environment(PlanetsCoordinator.self) private var coordinator
    // …and an ancestor: every coordinator above this view is injected too.
    @Environment(AppCoordinator.self) private var tabs

    let name: String

    var body: some View {
        VStack(spacing: 20) {
            Text(name).font(.largeTitle)

            Button("Add to Favorites") {
                // Switch tabs and act on that tab's flow. `expecting:` hands
                // the resolved child straight back, so the code stays flat.
                let favorites = tabs.selectFirstTab(.favorites, expecting: FavoritesCoordinator.self)
                favorites?.add(name)
            }
            .buttonStyle(.borderedProminent)
        }
        .navigationTitle(name)
    }
}
