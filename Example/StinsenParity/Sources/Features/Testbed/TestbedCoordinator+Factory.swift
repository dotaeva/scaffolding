import SwiftUI
import Scaffolding

// MARK: - Factory

extension TestbedCoordinator {
    func makeTestbed() -> some View { TestbedScreen() }

    func makeScreen(label: String) -> some View { TestbedLeafScreen(label: label) }

    func makeSheet(label: String, expanded: Bool) -> some View {
        TestbedLeafScreen(label: label)
            .presentationDetents(expanded ? [.medium, .large] : [.medium])
    }

    func makeLockedSheet() -> some View {
        TestbedLeafScreen(label: "Locked", isLocked: true)
            .presentationDetents([.medium])
            .interactiveDismissDisabled(true)
    }

    /// The next generation down, so a nested testbed can say how deep it is.
    func makeChildTestbed() -> any Coordinatable {
        TestbedCoordinator(toasts: toasts, generation: generation + 1)
    }

    func makePicker() -> any Coordinatable { PickerCoordinator() }
}
