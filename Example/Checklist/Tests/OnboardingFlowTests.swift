import Testing
import Scaffolding
import ScaffoldingTesting
@testable import Checklist

/// Pushes, the `.distinct` guard, `onDismiss`, and result delivery through
/// the presenter-installed closure.
@MainActor
@Suite("Onboarding flow")
struct OnboardingFlowTests {
    private func makeFlow(
        onComplete: @escaping @MainActor () -> Void = { }
    ) -> OnboardingCoordinator {
        OnboardingCoordinator(store: TodoStore(), onComplete: onComplete).activated()
    }

    @Test("steps push in order and popToRoot restarts the flow")
    func steps() {
        let flow = makeFlow()

        flow.showPreferences()
        flow.showReady()

        #expect(flow.depth == 2)
        #expect(flow.topDestination == .ready)

        flow.startOver()
        #expect(flow.depth == 0)
        #expect(flow.topDestination == .welcome)
    }

    @Test(".distinct swallows a double tap of the same step")
    func distinctGuard() {
        let flow = makeFlow()

        flow.showPreferences()
        flow.showPreferences()

        #expect(flow.count(of: .preferences) == 1)
    }

    @Test("onDismiss fires exactly once, however the screen leaves")
    func onDismissOnce() {
        let flow = makeFlow()
        var dismissals = 0
        flow.route(to: .preferences) { dismissals += 1 }

        flow.popToRoot()   // not pop() — the callback must still fire
        flow.popToRoot()   // already at the root: no second call

        #expect(dismissals == 1)
    }

    @Test("finishing calls the completion exactly once")
    func completion() {
        var completions = 0
        let flow = makeFlow { completions += 1 }

        flow.finish()

        #expect(completions == 1)
    }

    @Test("preferences write straight through to the store")
    func preferencesWriteThrough() {
        let store = TodoStore()
        let viewModel = OnboardingViewModel(store: store)

        viewModel.sortByDueDate = false
        viewModel.showsCompleted = true

        #expect(!store.sortByDueDate)
        #expect(store.showsCompleted)
    }
}
