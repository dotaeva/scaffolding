import SwiftUI
import Observation
import Scaffolding

/// The detail column's flow: planet overview at the root, moon details
/// pushed on top. As a column child it builds its own NavigationStack
/// inside the split view — exactly the composition SwiftUI expects in a
/// NavigationSplitView column — so pushes, pops, and modals here are
/// ordinary flow calls.
@MainActor @Observable @Scaffoldable
final class PlanetCoordinator: @MainActor FlowCoordinatable {
    var stack = FlowStack<PlanetCoordinator>(root: .overview)

    let planet: Planet

    init(planetId: Planet.ID) {
        self.planet = SolarSystem.planet(id: planetId) ?? .fallback
    }

    // MARK: Routes

    func overview() -> some View { PlanetOverviewScreen(planet: planet) }
    func moon(moon: Moon) -> some View {
        MoonDetailScreen(planet: planet, moon: moon)
    }
}

// MARK: - Navigation

extension PlanetCoordinator {
    /// Inside the column, `.distinct` works as a double-tap guard the
    /// normal way — each push is compared against the top of this flow's
    /// own stack.
    func open(_ moon: Moon) {
        route(to: .moon(moon: moon), policy: .distinct)
    }
}
