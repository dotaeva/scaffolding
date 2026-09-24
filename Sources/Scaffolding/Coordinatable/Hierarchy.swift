//
//  Hierarchy.swift
//  Scaffolding
//
//  Created by Alexandr Valíček on 16.07.2026.
//

import SwiftUI

@MainActor
public extension Coordinatable {
    /// How this coordinator entered its parent: `.root`, `.push`, `.sheet`,
    /// or `.fullScreenCover`.
    ///
    /// Roots, tabs, split columns, and the top of the tree read `.root`. This
    /// can differ from a view's `@Environment(\.destination).routeType`: in a
    /// flow presented as a sheet, the coordinator reads `.sheet` while a pushed
    /// screen reads `.push`. Check ``DestinationType/isModal`` before offering
    /// Close. See <doc:Orientation>.
    var routeType: DestinationType {
        _owningDestination()?.routeType ?? .root
    }

    /// Returns the nearest ancestor of the given type, or `nil` when none matches.
    ///
    /// Walks ``parent`` upward, starting above this coordinator. Use it to
    /// call an action the ancestor owns:
    ///
    /// ```swift
    /// func signOut() {
    ///     ancestor(ofType: AppCoordinator.self)?.signOut()
    /// }
    /// ```
    ///
    /// Views read ancestors from the environment instead:
    /// `@Environment(AppCoordinator.self)`.
    ///
    /// Both need the ancestor's concrete type, so they suit single-module
    /// apps. A feature in its own package can't name its host; inject a
    /// capability instead. See <doc:MonolithicApps> and <doc:ModularApps>.
    func ancestor<T: Coordinatable>(ofType type: T.Type = T.self) -> T? {
        var node = parent
        while let current = node {
            if let match = current as? T { return match }
            node = current.parent
        }
        return nil
    }

    /// The top coordinator of this tree, or `self` when there is no parent.
    ///
    /// Print the whole tree from anywhere with
    /// `print(coordinator.hierarchyRoot.debugHierarchy())`.
    var hierarchyRoot: any Coordinatable {
        var node: any Coordinatable = self
        while let parent = node.parent {
            node = parent
        }
        return node
    }
}
