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
    func debugHierarchy() -> String {
        var lines: [String] = []
        _appendHierarchy(to: &lines, label: nil, indent: "")
        return lines.joined(separator: "\n")
    }
}

@MainActor
extension Coordinatable {
    private var _kindLabel: String {
        if self is any FlowCoordinatable { return "flow" }
        if self is any TabCoordinatable { return "tab" }
        if self is any RootCoordinatable { return "root" }
        return "coordinator"
    }

    func _appendHierarchy(to lines: inout [String], label: String?, indent: String) {
        let header = "\(String(describing: type(of: self))) [\(_kindLabel)]"
        lines.append("\(indent)\(label.map { "\($0) → " } ?? "")\(header)")

        let childIndent = indent + "  "

        if let flow = self as? any FlowCoordinatable {
            if let root = flow.anyStack.root {
                _appendDestination(root, role: "root", to: &lines, indent: childIndent)
            }
            for destination in flow.anyStack.destinations {
                _appendDestination(
                    destination,
                    role: _roleLabel(for: destination.pushType),
                    to: &lines,
                    indent: childIndent
                )
            }
        } else if let tab = self as? any TabCoordinatable {
            let items = tab.anyTabItems
            for (index, destination) in items.tabs.enumerated() {
                let selectedMark = destination.id == items.selectedTab ? "*" : ""
                _appendDestination(
                    destination,
                    role: "tab[\(index)]\(selectedMark)",
                    to: &lines,
                    indent: childIndent
                )
            }
            for destination in items.modals {
                _appendDestination(
                    destination,
                    role: _roleLabel(for: destination.pushType),
                    to: &lines,
                    indent: childIndent
                )
            }
        } else if let root = self as? any RootCoordinatable {
            if let rootDestination = root.anyRoot.root {
                _appendDestination(rootDestination, role: "root", to: &lines, indent: childIndent)
            }
            for destination in root.anyRoot.modals {
                _appendDestination(
                    destination,
                    role: _roleLabel(for: destination.pushType),
                    to: &lines,
                    indent: childIndent
                )
            }
        }
    }

    private func _roleLabel(for pushType: PresentationType?) -> String {
        switch pushType {
        case .push: return "push"
        case .sheet: return "sheet"
        case .fullScreenCover: return "fullScreenCover"
        case nil: return "root"
        }
    }

    private func _appendDestination(
        _ destination: Destination,
        role: String,
        to lines: inout [String],
        indent: String
    ) {
        let metaText = ".\(String(describing: destination.meta))"

        guard destination.hasCoordinatable else {
            lines.append("\(indent)\(role) \(metaText)")
            return
        }

        guard let child = destination.materializedCoordinatable else {
            lines.append("\(indent)\(role) \(metaText) → (not yet created)")
            return
        }

        child._appendHierarchy(to: &lines, label: "\(role) \(metaText)", indent: indent)
    }
}
