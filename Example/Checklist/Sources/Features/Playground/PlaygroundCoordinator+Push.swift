import SwiftUI
import Scaffolding

// MARK: - Push, replace, pop

extension PlaygroundCoordinator {
    /// `.always`: the stack grows, so the pop family has work to do.
    func push() { route(to: .playground) }

    /// A different case each time, with `onDismiss` counting removals.
    func pushLeaf() {
        route(to: .leaf(label: "Leaf \(count(of: .leaf) + 1)")) { [weak self] in
            self?.dismissals += 1
        }
    }

    /// `.distinct` skips when the same *case* is already on top — tap it
    /// twice and only the first lands.
    func pushLeafDistinct() {
        route(to: .leaf(label: "Distinct"), policy: .distinct)
    }

    /// Pushes a whole child coordinator; it gets its own routes and can
    /// dismiss itself off this stack.
    func pushChild() { route(to: .child, policy: .distinct) }

    /// Swaps the top screen, so "back" skips the one replaced.
    func replaceTop() { replaceLast(with: .leaf(label: "Replaced")) }

    /// Swaps the flow's root and clears everything above it.
    func swapRoot() { setRoot(.leaf(label: "New root")) }

    func restoreRoot() { setRoot(.playground) }

    /// True when `setRoot` replaced the playground root with a leaf.
    ///
    /// A root swap tears down the screen the button was tapped on, so the
    /// control that undoes it cannot live there. The leaf asks this and
    /// offers the way back itself. `topDestination` reports the *root's*
    /// meta once nothing is pushed, so this reads as "at the root, and the
    /// root is a leaf".
    var isRootSwapped: Bool {
        depth == 0 && topDestination == .leaf
    }
}
