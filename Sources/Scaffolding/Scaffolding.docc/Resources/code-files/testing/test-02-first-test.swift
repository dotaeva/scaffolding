import Testing
import Scaffolding
import ScaffoldingTesting
@testable import Planets

@MainActor                       // coordinators are MainActor-isolated
@Suite("Planets flow")
struct PlanetsFlowTests {

    @Test("a fresh flow sits at its root")
    func startsAtRoot() {
        // activated() resolves the initial root, which the framework would do
        // on first render. A test renders nothing.
        let planets = PlanetsCoordinator().activated()

        #expect(planets.depth == 0)
        #expect(planets.topDestination == .planets)
        #expect(!planets.isPresentingModal)
    }

    @Test("opening a planet pushes one screen")
    func openPushes() {
        let planets = PlanetsCoordinator().activated()

        planets.route(to: .detail(name: "Mars"))

        #expect(planets.depth == 1)
        #expect(planets.topDestination == .detail)
        #expect(planets.isInStack(.detail))
    }
}
