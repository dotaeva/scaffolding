//
//  DebugHierarchy.swift
//  Scaffolding
//
//  Created by Alexandr Valíček on 05.07.2026.
//

import SwiftUI

@MainActor
public extension Coordinatable {
    /// Returns a printable snapshot of the live coordinator tree rooted at
    /// this coordinator.
    ///
    /// Each line shows a destination's role (root, push, sheet,
    /// full-screen cover, tab), its `Destinations` case, and — when the
    /// destination is backed by a child coordinator — the child's type and
    /// contents, recursively. The selected tab is marked with `*`.
    ///
    /// ```
    /// AppRootCoordinator [root]
    ///   root .main → MainTabCoordinator [tab]
    ///     tab[0]* .home → HomeFlowCoordinator [flow]
    ///       root .home
    ///       push .settings
    ///       sheet .sheetFlow → LeafFlowCoordinator [flow]
    ///         root .leaf
    ///     tab[1] .profile → ProfileFlowCoordinator [flow]
    ///       root .profile
    /// ```
    ///
    /// Inspecting the tree has no side effects: in the rare case where a
    /// destination's child coordinator has not been created yet, it is
    /// reported as `(not yet created)` rather than being materialised.
    ///
    /// For assertions and debug UIs, prefer the structured
    /// ``hierarchySnapshot()`` over matching this string.
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
