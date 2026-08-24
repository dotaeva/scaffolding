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
    // The route table: one line per destination, with the bodies in
    // PlaygroundChildCoordinator+Factory.swift. These declarations have to stay in the class
    // body — @Scaffoldable scans only the class declaration, so a route
    // moved to an extension is silently untracked.

    func child() -> some View { makeChild() }
    func grandchild() -> some View { makeGrandchild() }
}

// MARK: - Navigation

extension PlaygroundChildCoordinator {
    /// Pushes onto the *parent's* NavigationStack — a child flow shares it.
    func pushGrandchild() { route(to: .grandchild, policy: .distinct) }
}
