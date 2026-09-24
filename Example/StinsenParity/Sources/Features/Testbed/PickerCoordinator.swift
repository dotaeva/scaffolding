import SwiftUI
import Scaffolding

/// A one-screen sub-flow that returns a number.
///
/// It opts out of environment injection, so its screen is handed the
/// coordinator explicitly — the other half of the injection story.
@MainActor
@Observable
@Scaffoldable(injectsCoordinator: false)
final class PickerCoordinator: @MainActor FlowCoordinatable {
    var stack = FlowStack<PickerCoordinator>(root: .picker)

    // MARK: Routes

    func picker() -> some View { makePicker() }
}

// MARK: - Factory

extension PickerCoordinator {
    /// The flow opted out of environment injection, so the screen is
    /// handed its coordinator explicitly.
    func makePicker() -> some View { PickerScreen(coordinator: self) }
}

// MARK: - Result

extension PickerCoordinator {
    func pick(_ value: Int) {
        dismissCoordinator(returning: value)
    }

    /// Resumes the awaiting presenter with `nil`.
    func cancel() {
        dismissCoordinator()
    }
}

// MARK: - Presented content

extension PickerCoordinator {
    func customize(_ view: AnyView) -> some View {
        view.presentationDetents([.medium])
    }
}
