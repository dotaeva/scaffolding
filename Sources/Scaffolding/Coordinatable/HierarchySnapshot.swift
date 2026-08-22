//
//  HierarchySnapshot.swift
//  Scaffolding
//

import SwiftUI

/// The role a destination plays inside the coordinator that owns it.
public enum HierarchyRole: Equatable, Sendable {
    /// The coordinator's root destination.
    case root
    /// A destination pushed onto a flow's stack.
    case push
    /// A destination presented as a sheet.
    case sheet
    /// A destination presented as a full-screen cover.
    case fullScreenCover
    /// A tab, with its index and whether it is currently selected.
    case tab(index: Int, isSelected: Bool)
    /// A column of a split view (sidebar, content, or detail).
    case column(SplitColumn)

    /// Whether the destination is presented modally.
    public var isModal: Bool {
        self == .sheet || self == .fullScreenCover
    }

    /// Whether the destination is a tab.
    public var isTab: Bool {
        if case .tab = self { return true }
        return false
    }

    /// Whether the destination is a split-view column.
    public var isColumn: Bool {
        if case .column = self { return true }
        return false
    }
}

/// One destination in a snapshot of the live coordinator tree.
///
/// Snapshots are side-effect free: a destination whose child coordinator has
/// not been created yet reports ``coordinator`` as `nil` while
/// ``hasCoordinator`` stays `true`, and is never materialised by inspection.
@MainActor
public struct HierarchyNode {
    /// How the destination is displayed by its owner.
    public let role: HierarchyRole

    /// Metadata identifying which `Destinations` case this destination is.
    public let meta: any DestinationMeta

    /// The destination's child coordinator, if one has already been created.
    public let coordinator: (any Coordinatable)?

    /// Whether the destination is backed by a child coordinator at all,
    /// created or not.
    public let hasCoordinator: Bool

    /// The child coordinator's own destinations, recursively.
    public let children: [HierarchyNode]

    /// `.someCase`, as rendered by ``Coordinatable/debugHierarchy()``.
    public var metaDescription: String {
        ".\(String(describing: meta))"
    }
}

@MainActor
public extension Coordinatable {
    /// Returns a snapshot of this coordinator's destinations, recursively.
    ///
    /// This is the structured form of ``debugHierarchy()`` — use it to drive
    /// a debug UI, or to assert on navigation state without matching strings:
    ///
    /// ```swift
    /// let pushed = coordinator.hierarchySnapshot()
    ///     .filter { $0.role == .push }
    /// ```
    ///
    /// Inspecting the tree has no side effects; child coordinators that have
    /// not been created yet are reported as ``HierarchyNode/hasCoordinator``
    /// with a `nil` ``HierarchyNode/coordinator``.
    func hierarchySnapshot() -> [HierarchyNode] {
        if let flow = self as? any FlowCoordinatable {
            var nodes: [HierarchyNode] = []
            if let root = flow.anyStack.root {
                nodes.append(_node(for: root, role: .root))
            }
            for destination in flow.anyStack.destinations {
                nodes.append(_node(for: destination, role: .init(destination.pushType)))
            }
            return nodes
        }

        if let tab = self as? any TabCoordinatable {
            let items = tab.anyTabItems
            var nodes = items.tabs.enumerated().map { index, destination in
                _node(
                    for: destination,
                    role: .tab(index: index, isSelected: destination.id == items.selectedTab)
                )
            }
            nodes += items.modals.map { _node(for: $0, role: .init($0.pushType)) }
            return nodes
        }

        if let root = self as? any RootCoordinatable {
            var nodes: [HierarchyNode] = []
            if let rootDestination = root.anyRoot.root {
                nodes.append(_node(for: rootDestination, role: .root))
            }
            nodes += root.anyRoot.modals.map { _node(for: $0, role: .init($0.pushType)) }
            return nodes
        }

        if let split = self as? any SplitCoordinatable {
            let columns = split.anySplitColumns
            var nodes: [HierarchyNode] = []
            if let sidebar = columns.sidebar {
                nodes.append(_node(for: sidebar, role: .column(.sidebar)))
            }
            if let content = columns.content {
                nodes.append(_node(for: content, role: .column(.content)))
            }
            if let detail = columns.detail {
                nodes.append(_node(for: detail, role: .column(.detail)))
            }
            nodes += columns.modals.map { _node(for: $0, role: .init($0.pushType)) }
            return nodes
        }

        return []
    }
}

@MainActor
extension Coordinatable {
    /// Label used by ``debugHierarchy()`` for this coordinator's kind.
    var _kindLabel: String {
        if self is any FlowCoordinatable { return "flow" }
        if self is any TabCoordinatable { return "tab" }
        if self is any RootCoordinatable { return "root" }
        if self is any SplitCoordinatable { return "split" }
        return "coordinator"
    }

    private func _node(for destination: Destination, role: HierarchyRole) -> HierarchyNode {
        let child = destination.materializedCoordinatable
        return HierarchyNode(
            role: role,
            meta: destination.meta,
            coordinator: child,
            hasCoordinator: destination.hasCoordinatable,
            children: child?.hierarchySnapshot() ?? []
        )
    }
}

extension HierarchyRole {
    init(_ pushType: PresentationType?) {
        switch pushType {
        case .push: self = .push
        case .sheet: self = .sheet
        case .fullScreenCover: self = .fullScreenCover
        case nil: self = .root
        }
    }

    /// The role's label in ``Coordinatable/debugHierarchy()`` output.
    var debugLabel: String {
        switch self {
        case .root: return "root"
        case .push: return "push"
        case .sheet: return "sheet"
        case .fullScreenCover: return "fullScreenCover"
        case .tab(let index, let isSelected): return "tab[\(index)]\(isSelected ? "*" : "")"
        case .column(let column): return column.rawValue
        }
    }
}
