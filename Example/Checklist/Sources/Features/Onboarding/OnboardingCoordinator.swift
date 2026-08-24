import SwiftUI
import Scaffolding

/// First-launch flow: welcome → preferences → ready. The result is
/// delivered through the closure the presenter installed at construction
/// time, and `AppCoordinator` swaps the root — the child never reaches
/// back up the tree.
@MainActor
@Observable
@Scaffoldable
final class OnboardingCoordinator: @MainActor FlowCoordinatable {
    var stack = FlowStack<OnboardingCoordinator>(root: .welcome)

    private let store: TodoStore
    private let onComplete: @MainActor () -> Void

    init(store: TodoStore, onComplete: @escaping @MainActor () -> Void) {
        self.store = store
        self.onComplete = onComplete
    }

    // MARK: Routes

    func welcome() -> some View { WelcomeView() }

    func preferences() -> some View {
        PreferencesStepView(viewModel: OnboardingViewModel(store: store))
    }

    func ready() -> some View { ReadyView() }

    // Genuinely needs @ScaffoldingIgnored: it is declared in the class
    // body and returns `some View`, so the macro would otherwise emit a
    // bogus `.customize` destination. (The other coordinators declare
    // `customize` in an extension, where the macro never sees it — both
    // placements appear in this app on purpose.)
    @ScaffoldingIgnored
    func customize(_ view: AnyView) -> some View {
        view.tint(.accentColor)
    }
}

// MARK: - Steps
// Void return types are never macro-tracked — no attribute needed.

extension OnboardingCoordinator {
    func showPreferences() {
        // .distinct guards the double-tap while the push animates.
        route(to: .preferences, policy: .distinct)
    }

    func showReady() {
        route(to: .ready, policy: .distinct)
    }

    /// Restarts the flow without dismissing it.
    func startOver() {
        popToRoot()
    }

    func finish() {
        onComplete()
    }
}
