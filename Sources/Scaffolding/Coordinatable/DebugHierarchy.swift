//
//  DebugHierarchy.swift
//  Scaffolding
//
//  Created by Alexandr Valíček on 05.07.2026.
//

import SwiftUI

@MainActor
public extension Coordinatable {
    /// Returns the coordinator tree below this coordinator as indented text.
    ///
    /// Each line shows a destination's role, its case, and, for a child
    /// coordinator, the child's type and kind. `*` marks the selected tab.
    ///
    /// ```
    /// AppCoordinator [root]
    ///   root .main → MainTabCoordinator [tab]
    ///     tab[0]* .home → HomeCoordinator [flow]
    ///       root .home
    ///       push .detail
    ///       sheet .settings → SettingsCoordinator [flow]
    ///         root .settings
    ///     tab[1] .profile → ProfileCoordinator [flow]
    ///       root .profile
    /// ```
    ///
    /// Like ``hierarchySnapshot()``, it creates nothing; a child that does not
    /// exist yet prints as `(not yet created)`. For structured assertions, use
    /// ``hierarchySnapshot()``.
    func debugHierarchy() -> String {
        var lines = ["\(String(describing: type(of: self))) [\(_kindLabel)]"]
        _appendNodes(hierarchySnapshot(), to: &lines, indent: "  ")
        return lines.joined(separator: "\n")
    }
}

@MainActor
private func _appendNodes(
    _ nodes: [HierarchyNode],
    to lines: inout [String],
    indent: String
) {
    for node in nodes {
        let label = "\(node.role.debugLabel) \(node.metaDescription)"

        guard node.hasCoordinator else {
            lines.append("\(indent)\(label)")
            continue
        }

        guard let child = node.coordinator else {
            lines.append("\(indent)\(label) → (not yet created)")
            continue
        }

        lines.append("\(indent)\(label) → \(String(describing: type(of: child))) [\(child._kindLabel)]")
        _appendNodes(node.children, to: &lines, indent: indent + "  ")
    }
}
