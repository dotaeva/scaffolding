import SwiftUI
import Observation
import Scaffolding

// MARK: - Deep links

extension SolarSystemCoordinator {
    /// solar://planet/mars · solar://planet/jupiter/moon/europa
    func handle(_ url: URL) {
        guard url.scheme == "solar",
              let planet = SolarSystem.planet(id: url.host() ?? "")
        else { return }

        let moonName = url.pathComponents.count >= 3 ? url.pathComponents[2] : nil
        show(planet, moon: moonName.flatMap { planet.moon(named: $0) })
    }

    /// Lands on a planet — and optionally one of its moons. The typed
    /// trailing closure hands over the freshly resolved detail flow, so
    /// the walk continues into the column without storing any reference.
    func show(_ planet: Planet, moon: Moon? = nil) {
        selectedPlanetId = planet.id

        setDetail(.planet(id: planet.id)) { (flow: PlanetCoordinator) in
            if let moon {
                flow.route(to: .moon(moon: moon))
            }
        }

        // When the split view is collapsed (iPhone, narrow iPad windows),
        // land on the detail column instead of the sidebar.
        setPreferredCompactColumn(.detail)
    }
}
