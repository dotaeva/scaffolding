import SwiftUI
import Scaffolding

/// First-launch flow: welcome → units → ready. Completion is delivered
/// through the closure installed by the presenter (AppCoordinator), which
/// then swaps the root — the child never reaches back up the tree.
///
/// Deliberately *not* `codable:` — whole-tree capture records this subtree
/// without its internal state, demonstrating graceful degradation.
@MainActor
@Observable
@Scaffoldable
final class OnboardingCoordinator: @MainActor FlowCoordinatable {
    var stack = FlowStack<OnboardingCoordinator>(root: .welcome)

    private let store: WeatherStore
    private let onComplete: @MainActor () -> Void

    init(store: WeatherStore, onComplete: @escaping @MainActor () -> Void) {
        self.store = store
        self.onComplete = onComplete
    }

    // MARK: Routes

    func welcome() -> some View { WelcomeScreen() }
    func units() -> some View { UnitsStepScreen() }
    func ready() -> some View { ReadyScreen() }

    // Genuinely needs @ScaffoldingIgnored: declared in the class body with
    // a `some View` return type, so the macro would otherwise emit a bogus
    // `.customize` destination. (Declaring it in an extension — as the
    // other coordinators do — needs no attribute; both placements shown
    // across this app on purpose.)
    @ScaffoldingIgnored
    func customize(_ view: AnyView) -> some View {
        view.skyBackground(.partlyCloudy)
    }
}

// MARK: - Steps
// Void return types are never macro-tracked — no attribute needed.

extension OnboardingCoordinator {
    func showUnits() {
        // .distinct guards the double-tap while the push animates.
        route(to: .units, policy: .distinct)
    }

    func choose(_ units: Units) {
        store.units = units
        route(to: .ready, policy: .distinct)
    }

    /// Restarts the flow without dismissing it — pops back to the root.
    func startOver() {
        popToRoot()
    }

    func finish() {
        onComplete()
    }
}
