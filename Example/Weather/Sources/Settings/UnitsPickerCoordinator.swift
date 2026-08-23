import SwiftUI
import Scaffolding

/// A one-screen sub-flow that returns the chosen units.
///
/// `injectsCoordinator: false` opts this coordinator out of environment
/// injection — its screens cannot read it via
/// `@Environment(UnitsPickerCoordinator.self)`, so the route function
/// hands it over explicitly. Useful when a reusable screen shouldn't bind
/// to a specific flow. (Ancestors are still injected as usual.)
@MainActor
@Observable
@Scaffoldable(injectsCoordinator: false)
final class UnitsPickerCoordinator: @MainActor FlowCoordinatable {
    var stack = FlowStack<UnitsPickerCoordinator>(root: .picker)

    let current: Units

    init(current: Units) {
        self.current = current
    }

    // MARK: Routes

    func picker() -> some View {
        // Explicit init injection instead of the environment.
        UnitsPickerScreen(coordinator: self, current: current)
    }
}

// MARK: - Result

extension UnitsPickerCoordinator {
    func pick(_ units: Units) {
        dismissCoordinator(returning: units)
    }

    func cancel() {
        dismissCoordinator()   // presenter's awaiting: resumes with nil
    }
}
