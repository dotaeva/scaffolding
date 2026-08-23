import Testing
import Scaffolding
import ScaffoldingTesting
@testable import Weather

/// The first-launch flow: pushes, the .distinct double-tap guard, and
/// result delivery through the presenter-installed closure.
@MainActor
@Suite("Onboarding flow")
struct OnboardingFlowTests {

    @Test("steps push in order and popToRoot restarts")
    func stepsAndRestart() {
        let store = WeatherStore()
        let onboarding = OnboardingCoordinator(store: store, onComplete: { }).activated()

        onboarding.showUnits()
        onboarding.choose(.fahrenheit)

        #expect(onboarding.depth == 2)
        #expect(onboarding.topDestination == .ready)
        #expect(store.units == .fahrenheit)

        onboarding.startOver()
        #expect(onboarding.depth == 0)
        #expect(onboarding.topDestination == .welcome)
    }

    @Test(".distinct swallows a double tap of the same step")
    func distinctGuard() {
        let onboarding = OnboardingCoordinator(store: WeatherStore(), onComplete: { }).activated()

        onboarding.showUnits()
        onboarding.showUnits()   // second tap while the push animates

        #expect(onboarding.count(of: .units) == 1)
    }

    @Test("onDismiss fires exactly once, however the screen leaves")
    func onDismissFiresOnce() {
        let onboarding = OnboardingCoordinator(store: WeatherStore(), onComplete: { }).activated()
        var dismissals = 0
        onboarding.route(to: .units) { dismissals += 1 }

        onboarding.popToRoot()   // not pop() — the callback must still fire
        onboarding.popToRoot()   // already at the root: no second call

        #expect(dismissals == 1)
    }

    @Test("finishing calls the completion exactly once")
    func completionDelivery() {
        var completions = 0
        let onboarding = OnboardingCoordinator(store: WeatherStore()) {
            completions += 1
        }.activated()

        onboarding.finish()

        #expect(completions == 1)
    }
}
