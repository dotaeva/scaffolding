import Testing
import Scaffolding
import ScaffoldingTesting
@testable import Planets

@MainActor
@Suite("Push policies")
struct PushPolicyTests {

    @Test("RoutePolicy.distinct swallows a double tap")
    func distinctSkipsDuplicate() {
        let planets = PlanetsCoordinator().activated()

        planets.route(to: .detail(name: "Mars"), policy: .distinct)
        planets.route(to: .detail(name: "Mars"), policy: .distinct)

        #expect(planets.count(of: .detail) == 1)
    }

    @Test("routeAndWait resumes when the pushed screen leaves")
    func awaitedPushResumes() async {
        let planets = PlanetsCoordinator().activated()

        let waiting = Task { await planets.routeAndWait(to: .detail(name: "Mars")) }
        // waitUntil spins the main actor so the task above gets to run.
        await waitUntil { planets.depth == 1 }

        // pop(), popToRoot(), a back swipe, or the whole coordinator being
        // dismissed all resume the suspension — exactly once, whichever
        // happens first.
        planets.popToRoot()
        await waiting.value

        #expect(planets.depth == 0)
    }

    @Test("a seeded stack starts deep")
    func seededStack() {
        let planets = PlanetsCoordinator(startingAt: "Mars").activated()

        #expect(planets.depth == 1)
        #expect(planets.topDestination == .detail)
    }
}
