import Testing
import Foundation
import Scaffolding
import ScaffoldingTesting
@testable import Planets

@MainActor
@Suite("Root swaps and deep links")
struct RootTests {

    @Test("a login flow signs in through its ancestor")
    func loginReachesTheRoot() {
        let app = AppRootCoordinator().activated()
        let login = app.setRoot(.login, expecting: LoginCoordinator.self)

        #expect(login?.ancestor(ofType: AppRootCoordinator.self) === app)

        login?.submit()

        #expect(app.isRoot(.main))
    }

    @Test("a deep link walks root → tab → flow")
    func deepLinkLands() throws {
        let app = AppRootCoordinator().activated()
        app.signIn()

        app.handle(try #require(URL(string: "planets://planet/Mars")))

        // One typed assertion for the whole tree — no string matching, and
        // nothing that does not exist yet gets created.
        #expect(app.hierarchyContains(PlanetsCoordinator.self, .detail, as: .push))
        #expect(app.hierarchyContains(AppCoordinator.self, .planets, as: .tab(index: 0, isSelected: true)))
    }

    @Test("deep links are ignored while unauthenticated")
    func deepLinkGuarded() throws {
        let app = AppRootCoordinator().activated()

        app.handle(try #require(URL(string: "planets://planet/Mars")))

        #expect(app.isRoot(.login))
        #expect(!app.hierarchyContains(PlanetsCoordinator.self, .detail))
        #expect(app.pendingURL != nil)     // deferred, not dropped
    }
}
