import SwiftUI
import Scaffolding

/// The Stinsen demo's testbed, which pushes and presents *itself* until
/// you get bored — plus everything Scaffolding adds on top.
///
/// Every button on the screen is one call, and the readouts above them
/// update as it lands. The recursion is the point: a testbed presented as
/// a sheet contains a testbed that can push a testbed, and each one
/// reports its own depth, generation, and how it was reached.
@MainActor
@Observable
@Scaffoldable
final class TestbedCoordinator: @MainActor FlowCoordinatable {
    var stack = FlowStack<TestbedCoordinator>(root: .testbed)

    let toasts: ToastCenter

    /// How many testbed coordinators deep this one is — the Stinsen
    /// screen's "Number in coordinator stack".
    let generation: Int

    /// How many pushed destinations have reported their dismissal, proving
    /// `onDismiss` fires exactly once however the screen left.
    var dismissals = 0

    init(toasts: ToastCenter, generation: Int = 1) {
        self.toasts = toasts
        self.generation = generation
    }

    // MARK: Routes

    func testbed() -> some View { makeTestbed() }

    func screen(label: String) -> some View { makeScreen(label: label) }

    func sheet(label: String, expanded: Bool) -> some View { makeSheet(label: label, expanded: expanded) }

    func lockedSheet() -> some View { makeLockedSheet() }

    /// A child *coordinator* on this same stack: it owns its own routes
    /// and `dismissCoordinator()` removes the whole thing, not one screen.
    func childTestbed() -> any Coordinatable { makeChildTestbed() }

    /// A sub-flow that exists to return a number.
    func picker() -> any Coordinatable { makePicker() }
}

// MARK: - Presented content

extension TestbedCoordinator {
    func customize(_ view: AnyView) -> some View {
        view.presentationDetents([.large])
    }
}
