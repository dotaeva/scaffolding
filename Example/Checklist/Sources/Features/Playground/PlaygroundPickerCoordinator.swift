import SwiftUI
import Scaffolding

/// A one-screen sub-flow that returns a number. Deliberately not
/// `codable:`, so whole-tree restoration records it without its state.
@MainActor
@Observable
@Scaffoldable(injectsCoordinator: false)
final class PlaygroundPickerCoordinator: @MainActor FlowCoordinatable {
    var stack = FlowStack<PlaygroundPickerCoordinator>(root: .picker)

    // MARK: Routes

    /// The flow opted out of environment injection, so the screen is
    /// handed its coordinator explicitly.
    func picker() -> some View { PlaygroundPickerView(coordinator: self) }
}

// MARK: - Result

extension PlaygroundPickerCoordinator {
    func pick(_ value: Int) { dismissCoordinator(returning: value) }

    /// Resumes the awaiting presenter with `nil`.
    func cancel() { dismissCoordinator() }
}

// MARK: - Chrome

extension PlaygroundPickerCoordinator {
    func customize(_ view: AnyView) -> some View {
        view.sheetSizing(minHeight: 300, idealHeight: 340)
    }
}
