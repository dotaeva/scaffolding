import SwiftUI
import Scaffolding

/// The sidebar column: a native selection list. Selection *highlight* is
/// view chrome, synced both ways with the coordinator's domain state —
/// navigation itself stays on the coordinator.
struct SidebarScreen: View {
    @Environment(SolarSystemCoordinator.self) private var coordinator

    @State private var selection: Planet.ID?

    var body: some View {
        List(selection: $selection) {
            ForEach(SolarSystem.all) { planet in
                Text(planet.name)
                    .tag(planet.id)
                    .badge(planet.moons.count)
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Solar System")
        .onAppear { selection = coordinator.selectedPlanetId }
        // Row tap → coordinator. Selection is optional-writable, so guard
        // against the clear that follows programmatic changes.
        .onChange(of: selection) { _, id in
            guard let id, let planet = SolarSystem.planet(id: id) else { return }
            coordinator.select(planet)
        }
        // Deep links → keep the highlight in sync.
        .onChange(of: coordinator.selectedPlanetId) { _, id in
            selection = id
        }
    }
}
