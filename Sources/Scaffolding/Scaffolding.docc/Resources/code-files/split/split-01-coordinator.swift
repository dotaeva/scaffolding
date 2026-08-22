import SwiftUI
import Observation
import Scaffolding

/// The app root: a NavigationSplitView whose columns are coordinator-owned
/// destinations. Column assignment lives in the SplitColumns initializer;
/// the route functions keep the ordinary auto-tracked return types.
@MainActor @Observable @Scaffoldable
final class SolarSystemCoordinator: @MainActor SplitCoordinatable {
    var columns = SplitColumns<SolarSystemCoordinator>(
        sidebar: .sidebar,
        detail: .placeholder    // shown before any selection
    )

    // MARK: Routes
    // Routes must live in the class body — @Scaffoldable scans only the
    // class declaration, never extensions.

    func sidebar() -> some View { SidebarScreen() }

    func placeholder() -> some View {
        ContentUnavailableView(
            "Pick a planet",
            systemImage: "globe.europe.africa.fill"
        )
    }

    // A flow in the detail column: pushes inside it are ordinary
    // route(to:) calls on the child coordinator.
    func planet(id: Planet.ID) -> any Coordinatable {
        PlanetCoordinator(planetId: id)
    }
}
