import SwiftUI
import Scaffolding

/// A child coordinator pushed onto the playground's stack: it owns its own
/// routes, and `dismissCoordinator()` removes the whole child rather than
/// one screen.
@MainActor
@Observable
@Scaffoldable(codable: true)
final class PlaygroundChildCoordinator: @MainActor FlowCoordinatable {
    var stack = FlowStack<PlaygroundChildCoordinator>(root: .child)

    // MARK: Routes

    func child() -> some View { PlaygroundChildView() }
    func grandchild() -> some View { PlaygroundLeafView(label: "Grandchild") }
}

// MARK: - Navigation

extension PlaygroundChildCoordinator {
    /// Pushes onto the *parent's* NavigationStack — a child flow shares it.
    func pushGrandchild() { route(to: .grandchild, policy: .distinct) }
}
