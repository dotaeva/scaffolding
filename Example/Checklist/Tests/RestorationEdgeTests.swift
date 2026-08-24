import Testing
import Scaffolding
import ScaffoldingTesting
@testable import Checklist

/// What restoration does when it *can't* replay everything — the paths
/// that keep a stale snapshot from breaking a launch.
@MainActor
@Suite("Restoration edges")
struct RestorationEdgeTests {

    @Test("a non-codable sub-flow restores at its initial position")
    func degradation() async throws {
        let app = AppCoordinator(layout: .tabs).activated()
        app.finishOnboarding()
        let today = app.descendant(ofType: MainTabCoordinator.self)?
            .selectFirstTab(.today, expecting: TodayCoordinator.self)?.activated()
        today?.addTodo()
        await waitUntil { today?.isPresentingModal == true }
        // A push inside the (non-codable) sub-flow — this depth is lost.
        today?.descendant(ofType: NewTodoCoordinator.self)?.activated().chooseList()

        let data = try app.captureNavigationState()

        let restored = AppCoordinator(layout: .tabs).activated()
        try restored.restoreNavigationState(from: data)

        // The modal itself is a codable route on TodayCoordinator, so it is
        // re-presented — but the sub-flow inside comes back at its root.
        let compose = restored.descendant(ofType: NewTodoCoordinator.self)?.activated()
        #expect(compose != nil)
        #expect(compose?.depth == 0)
    }

    @Test("a snapshot from another layout degrades instead of crashing")
    func crossLayoutSnapshot() throws {
        let tabApp = AppCoordinator(layout: .tabs).activated()
        tabApp.finishOnboarding()
        let data = try tabApp.captureNavigationState()

        let splitApp = AppCoordinator(layout: .split).activated()
        try splitApp.restoreNavigationState(from: data)

        // The root case matches, so the split shell is built; its own
        // columns simply stay where they started.
        #expect(splitApp.isRoot(.main))
        #expect(splitApp.descendant(ofType: MainSplitCoordinator.self) != nil)
    }
}
