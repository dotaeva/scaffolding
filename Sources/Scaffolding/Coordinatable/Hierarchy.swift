//
//  Hierarchy.swift
//  Scaffolding
//
//  Created by Alexandr Valíček on 16.07.2026.
//

import SwiftUI

@MainActor
public extension Coordinatable {
    /// How this coordinator was reached from its parent.
    ///
    /// - `.push` — routed onto a parent flow's stack.
    /// - `.sheet` / `.fullScreenCover` — presented modally.
    /// - `.root` — a flow's root destination, a tab child, a
    ///   `RootCoordinatable`'s root, or the top of the coordinator tree.
    ///
    /// The coordinator-side counterpart of the view-side
    /// `@Environment(\.destination).routeType`. The two can differ for the
    /// same screen: a view pushed inside a sheet-presented flow reads
    /// `.push` from its destination while the flow itself reads `.sheet`.
    ///
    /// Use it to make dismissal decisions without knowing the surrounding
    /// structure — e.g. a sub-flow that closes itself the same way
    /// regardless of how it was presented calls `dismissCoordinator()`,
    /// but one that only offers "Close" when modal checks
    /// `routeType.isModal` first.
    var routeType: DestinationType {
        _owningDestination()?.routeType ?? .root
    }

    /// This coordinator's nearest ancestor of the given type, walking the
    /// ``parent`` chain upward. `nil` when no ancestor matches.
    ///
    /// This is the coordinator-side way to reach up the tree — e.g. a
    /// flow exposing a sign-out action that belongs to the app root:
    ///
    /// ```swift
    /// func signOut() {
    ///     ancestor(ofType: AppCoordinator.self)?.setRoot(.unauthenticated)
    /// }
    /// ```
    ///
    /// Views don't need this: every ancestor coordinator is already
    /// injected into their environment
    /// (`@Environment(AppCoordinator.self)`).
    func ancestor<T: Coordinatable>(ofType type: T.Type = T.self) -> T? {
        var node = parent
        while let current = node {
            if let match = current as? T { return match }
            node = current.parent
        }
        return nil
    }

    /// The topmost coordinator of the tree this coordinator lives in —
    /// `self` when it has no parent.
    ///
    /// Handy with ``debugHierarchy()`` to dump the whole tree from
    /// anywhere: `print(coordinator.hierarchyRoot.debugHierarchy())`.
    var hierarchyRoot: any Coordinatable {
        var node: any Coordinatable = self
        while let parent = node.parent {
            node = parent
        }
        return node
    }
}
