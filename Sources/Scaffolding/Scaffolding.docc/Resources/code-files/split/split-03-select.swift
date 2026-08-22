import SwiftUI
import Observation
import Scaffolding

@MainActor @Observable @Scaffoldable
final class SolarSystemCoordinator: @MainActor SplitCoordinatable {
    var columns = SplitColumns<SolarSystemCoordinator>(
        sidebar: .sidebar,
        detail: .placeholder
    )

    /// Domain state, not navigation state: which planet the detail column
    /// shows. The sidebar reads it to highlight the selected row.
    private(set) var selectedPlanetId: Planet.ID?

    // MARK: Routes

    func sidebar() -> some View { SidebarScreen() }

    func placeholder() -> some View {
        ContentUnavailableView(
            "Pick a planet",
            systemImage: "globe.europe.africa.fill"
        )
    }

    func planet(id: Planet.ID) -> any Coordinatable {
        PlanetCoordinator(planetId: id)
    }
}

// MARK: - Selection

extension SolarSystemCoordinator {
    /// Sidebar row tap. `setDetail` REPLACES the column like a root swap —
    /// the previous detail (and anything pushed inside it) is torn down —
    /// so guard re-selection on domain state. `.distinct` can't do this:
    /// it compares case identity only, and every planet is the same
    /// `.planet` case.
    func select(_ planet: Planet) {
        guard selectedPlanetId != planet.id else { return }
        selectedPlanetId = planet.id
        setDetail(.planet(id: planet.id))
    }
}
