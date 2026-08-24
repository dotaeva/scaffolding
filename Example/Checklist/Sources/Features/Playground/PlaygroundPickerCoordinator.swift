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
    // The route table: one line per destination, with the bodies in
    // PlaygroundPickerCoordinator+Factory.swift. These declarations have to stay in the class
    // body — @Scaffoldable scans only the class declaration, so a route
    // moved to an extension is silently untracked.

    func picker() -> some View { makePicker() }
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
