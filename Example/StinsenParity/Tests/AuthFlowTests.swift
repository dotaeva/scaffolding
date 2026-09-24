import Testing
import Foundation
import Scaffolding
import ScaffoldingTesting
@testable import StinsenParity

/// The whole navigation layer is testable without rendering anything:
/// coordinators are plain @Observable classes and every call mutates
/// their state synchronously.
@MainActor
@Suite("Auth root swap")
struct AuthFlowTests {
    /// The tab shell is pinned rather than left to `ShellLayout.current`,
    /// so these assertions mean the same thing on an iPad simulator as on
    /// an iPhone one. `ShellLayoutTests` covers the choice itself.
    private func makeApp(layout: ShellLayout = .tabs) -> MainCoordinator {
        // A scratch UserDefaults keeps the tests from seeing each other's
        // sessions, or the simulator's.
        let defaults = UserDefaults(suiteName: "test.\(UUID().uuidString)")!
        return MainCoordinator(
            auth: AuthenticationService(defaults: defaults),
            layout: layout
        ).activated()
    }

    @Test("launches unauthenticated with no stored session")
    func launchesUnauthenticated() {
        let app = makeApp()

        #expect(app.isRoot(.unauthenticated))
    }

    @Test("signing in swaps the whole root")
    func signInSwapsRoot() {
        let app = makeApp()

        app.signIn(User.preview)

        #expect(app.isRoot(.authenticated))
        #expect(app.hierarchyContains(AuthenticatedCoordinator.self, .home, as: .tab(index: 0, isSelected: true)))
    }

    @Test("signing out from deep in the tree swaps back", arguments: [ShellLayout.tabs, .split])
    func signOutReachesTheRoot(layout: ShellLayout) {
        let app = makeApp(layout: layout)
        app.signIn(User.preview)
        // A tab shell resolves all four tabs up front; a split view builds
        // a column's flow only once its section is selected.
        app.descendant(ofType: AuthenticatedSplitCoordinator.self)?.select(.profile)

        // The Profile flow reaches the app root with ancestor(ofType:) —
        // the same call the view makes, from a tab or from a column.
        let profile = app.descendant(ofType: ProfileCoordinator.self)
        #expect(profile != nil)
        profile?.signOut()

        #expect(app.isRoot(.unauthenticated))
    }
}
