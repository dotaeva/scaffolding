import Testing
import Scaffolding
import ScaffoldingTesting
@testable import SolarSystem

@MainActor
@Suite("Solar system split navigation")
struct SolarSystemSplitTests {
    @Test("selecting a planet replaces the detail column")
    func selectionReplacesDetail() {
        let split = SolarSystemCoordinator().activated()

        split.select(.mars)

        #expect(split.detailDestination == .planet)
        #expect(split.isDetail(.planet))
        #expect(split.hierarchyContains(SolarSystemCoordinator.self, .planet, as: .column(.detail)))
    }

    @Test("re-selecting the same planet keeps the detail flow's state")
    func reselectionKeepsState() {
        let split = SolarSystemCoordinator().activated()

        split.select(.mars)
        let flow = split.descendant(ofType: PlanetCoordinator.self)
        flow?.open(.phobos)

        split.select(.mars)   // guarded on domain state → no rebuild

        #expect(split.descendant(ofType: PlanetCoordinator.self) === flow)
        #expect(flow?.depth == 1)
        #expect(split.hierarchyContains(PlanetCoordinator.self, .moon, as: .push))
    }

    @Test("a deep link lands the moon inside the fresh detail flow")
    func deepLinkLandsMoon() {
        let split = SolarSystemCoordinator().activated()

        split.handle(URL(string: "solar://jupiter/moon/europa")!)

        #expect(split.hierarchyContains(PlanetCoordinator.self, .moon, as: .push))
    }
}
