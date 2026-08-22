import SwiftUI
import Observation
import Scaffolding

// MARK: - Three-column layout

extension SolarSystemCoordinator {
    /// Whether the moon list currently occupies a middle content column.
    var usesThreeColumns: Bool {
        columns.hasContentColumn
    }

    /// Installs or removes the middle content column at runtime — the
    /// rendered container swaps between NavigationSplitView's two- and
    /// three-column forms. (A split can also start three-column via
    /// SplitColumns(sidebar:content:detail:).)
    func setThreeColumnLayout(_ enabled: Bool) {
        if enabled {
            if let selectedPlanetId {
                setContent(.moons(id: selectedPlanetId))
            } else {
                setContent(.moonsPlaceholder)
            }
        } else {
            removeContent()
        }
    }

    /// In the three-column shape, selecting updates BOTH leading columns:
    /// the moon list follows the planet, the detail shows the overview.
    func select(_ planet: Planet) {
        guard selectedPlanetId != planet.id else { return }
        selectedPlanetId = planet.id

        if usesThreeColumns {
            setContent(.moons(id: planet.id))
        }
        setDetail(.planet(id: planet.id))
    }

    /// Moon-list row tap: in this shape a moon REPLACES the detail column
    /// instead of pushing inside it.
    func selectMoon(_ moon: Moon, of planet: Planet) {
        setDetail(.moonDetail(planetId: planet.id, moonId: moon.id))
    }
}
