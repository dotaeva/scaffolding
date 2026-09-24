import SwiftUI
import Scaffolding

// MARK: - Push, replace, pop

extension TestbedCoordinator {
    /// A different label each time, with `onDismiss` counting removals —
    /// it fires exactly once however the screen leaves: a back swipe, a
    /// pop, or the whole coordinator going away.
    func pushScreen() {
        let label = "Screen \(count(of: .screen) + 1)"
        route(to: .screen(label: label)) { [weak self] in
            self?.dismissals += 1
            self?.toasts.showNeutral("onDismiss: \(label)", symbol: "arrow.uturn.backward")
        }
    }

    /// `.distinct` skips the push when the same *case* is already on top —
    /// tap it twice and only the first lands.
    func pushDistinct() {
        route(to: .screen(label: "Distinct"), policy: .distinct)
    }

    /// Pushes a whole child coordinator onto this stack. It shares the
    /// NavigationStack, so its own pushes continue the same stack.
    func pushChild() {
        route(to: .childTestbed, policy: .distinct)
    }

    /// Swaps the top screen, so "back" skips the one replaced.
    func replaceTop() {
        replaceLast(with: .screen(label: "Replaced"))
    }

    /// Swaps this flow's root and clears everything above it.
    ///
    /// The catch worth demonstrating: this destroys the screen holding the
    /// button that would swap it back. So the way back ships with the
    /// action — on the toast for the next few seconds, and permanently on
    /// the new root screen, which asks ``isRootSwapped`` whether it is
    /// standing where the testbed used to be.
    func swapRoot() {
        setRoot(.screen(label: "New root"))
        toasts.show(
            "Root swapped — the testbed is gone",
            symbol: "arrow.2.squarepath",
            actionTitle: "Undo"
        ) { [weak self] in
            self?.restoreRoot()
        }
    }

    func restoreRoot() {
        setRoot(.testbed)
    }

    /// True when `setRoot` replaced the testbed root with a leaf screen.
    ///
    /// `topDestination` reports the *root's* meta once nothing is pushed,
    /// so this is "the flow is at its root, and that root is a screen".
    var isRootSwapped: Bool {
        depth == 0 && topDestination == .screen
    }
}
