import Testing
import Scaffolding
import ScaffoldingTesting
@testable import Planets

@MainActor
@Suite("State restoration")
struct RestorationTests {

    @Test("a captured snapshot replays onto a rebuilt tree")
    func captureAndRestore() throws {
        let app = AppRootCoordinator().activated()
        let tabs = app.setRoot(.main, expecting: AppCoordinator.self)
        let planets = tabs?.selectFirstTab(.planets, expecting: PlanetsCoordinator.self)
        planets?.route(to: .detail(name: "Mars"))

        let snapshot = try app.captureNavigationState()

        app.signOut()
        #expect(app.isRoot(.login))
        #expect(!app.hierarchyContains(PlanetsCoordinator.self, .detail))

        // Restoration replays routes, so give it a fresh tree to land on.
        app.setRoot(.main, animation: nil)
        try app.restoreNavigationState(from: snapshot)

        #expect(app.isRoot(.main))
        #expect(app.hierarchyContains(PlanetsCoordinator.self, .detail, as: .push))
    }
}
