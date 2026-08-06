import Testing
import Foundation
import Scaffolding
import ScaffoldingTesting
@testable import Demo

/// Root swaps, reaching up the tree, deep links, and state restoration.
@MainActor
@Suite("App root")
struct AppRootTests {

    @Test("the app starts unauthenticated")
    func startsAtLogin() {
        let app = AppCoordinator().activated()

        #expect(app.isRoot(.login))
        #expect(!app.isRoot(.main))
    }

    @Test("signIn and signOut swap the whole tree")
    func rootSwaps() {
        let app = AppCoordinator().activated()

        app.signIn()
        #expect(app.isRoot(.main))

        app.signOut()
        #expect(app.isRoot(.login))
    }

    @Test("a root swap builds a fresh child, so old stacks don't survive")
    func rootSwapDiscardsState() {
        let app = AppCoordinator().activated()
        let first = app.setRoot(.login, expecting: LoginCoordinator.self)
        first?.continueWith(username: "someone@example.com")
        #expect(first?.depth == 1)

        app.signIn()
        let second = app.setRoot(.login, expecting: LoginCoordinator.self)

        #expect(second !== first)
        #expect(second?.depth == 0)
    }

    @Test("a nested flow reaches the root with ancestor(ofType:)")
    func childReachesAppCoordinator() {
        let app = AppCoordinator().activated()
        let login = app.setRoot(.login, expecting: LoginCoordinator.self)

        #expect(login?.ancestor(ofType: AppCoordinator.self) === app)
        #expect(login?.hierarchyRoot === app)

        login?.continueWith(username: "someone@example.com")
        #expect(login?.topDestination == .password)

        login?.submit()   // reaches up and swaps the root

        #expect(app.isRoot(.main))
    }

    @Test("root-level modals float above whatever the current root is")
    func rootModals() {
        let app = AppCoordinator().activated()

        app.showWhatsNew()
        app.showWhatsNew()   // .distinct — the second call is swallowed
        #expect(app.isPresentingModal)

        app.dismissAllModals()

        #expect(!app.isPresentingModal)
    }

    @Test("deep links are ignored while unauthenticated")
    func deepLinkGuardedByAuth() throws {
        let app = AppCoordinator().activated()

        app.handle(try #require(URL(string: "scaffolding-demo://holding/NVDA")))

        #expect(app.isRoot(.login))
        #expect(!app.debugHierarchy().contains("InvestCoordinator"))
    }

    @Test("a typed-closure deep link walks root → tab → flow")
    func deepLinkToHolding() throws {
        let app = AppCoordinator().activated()
        app.signIn()

        app.handle(try #require(URL(string: "scaffolding-demo://holding/NVDA")))

        // debugHierarchy() is the fastest way to assert on a whole tree —
        // and it never materialises coordinators that don't exist yet.
        let tree = app.debugHierarchy()
        #expect(tree.contains("tab[2]* .invest → InvestCoordinator"))
        #expect(tree.contains("push .holding"))
    }

    @Test("an expecting: deep link walks the same path")
    func deepLinkToTransaction() throws {
        let app = AppCoordinator().activated()
        app.signIn()

        app.handle(try #require(URL(string: "scaffolding-demo://transaction/2")))

        let tree = app.debugHierarchy()
        #expect(tree.contains("tab[0]* .home → HomeCoordinator"))
        #expect(tree.contains("push .transaction"))
    }

    @Test("captureNavigationState replays onto a rebuilt tree")
    func captureAndRestore() throws {
        let app = AppCoordinator().activated()
        app.signIn()
        app.handle(try #require(URL(string: "scaffolding-demo://transaction/2")))

        let snapshot = try app.captureNavigationState()

        app.signOut()
        #expect(app.isRoot(.login))
        #expect(!app.debugHierarchy().contains("push .transaction"))

        // Restoration replays routes, so it needs a fresh tree to land on —
        // the same reset AppCoordinator.restoreSnapshot() performs.
        app.setRoot(.main, animation: nil)
        try app.restoreNavigationState(from: snapshot)

        #expect(app.isRoot(.main))
        #expect(app.debugHierarchy().contains("push .transaction"))
    }

    @Test("a non-codable subtree degrades instead of failing the capture")
    func captureToleratesNonCodableSubtree() throws {
        // InvestCoordinator's buy route carries a closure payload, so it opts
        // out of `codable:` — its stack is skipped while the rest is kept.
        let app = AppCoordinator().activated()
        app.signIn()
        app.handle(try #require(URL(string: "scaffolding-demo://holding/NVDA")))

        let snapshot = try app.captureNavigationState()

        app.signOut()
        app.setRoot(.main, animation: nil)
        try app.restoreNavigationState(from: snapshot)

        #expect(app.isRoot(.main))
        // Tab selection came back; the invest flow restarts at its root.
        #expect(app.debugHierarchy().contains("tab[2]* .invest"))
        #expect(!app.debugHierarchy().contains("push .holding"))
    }
}
