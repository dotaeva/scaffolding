//
//  HierarchySnapshot.swift
//  Scaffolding
//

import SwiftUI

/// The role a destination plays in the coordinator that owns it.
public enum HierarchyRole: Equatable, Sendable {
    /// The coordinator's root destination.
    case root
    /// A screen or child pushed onto a flow.
    case push
    /// A modal presented as a sheet.
    case sheet
    /// A modal presented as a full-screen cover.
    case fullScreenCover
    /// The tab at `index`; `isSelected` marks the selected tab.
    case tab(index: Int, isSelected: Bool)
    /// A split-view column.
    case column(SplitColumn)

    /// Whether the role is `.sheet` or `.fullScreenCover`.
    public var isModal: Bool {
        self == .sheet || self == .fullScreenCover
    }

    /// Whether the role is a tab.
    public var isTab: Bool {
        if case .tab = self { return true }
        return false
    }

    /// Whether the role is a split-view column.
    public var isColumn: Bool {
        if case .column = self { return true }
        return false
    }
}

/// One destination in a snapshot of the coordinator tree.
///
/// Taking a snapshot never creates coordinators. A child that does not exist
/// yet has ``hasCoordinator`` set to `true` and ``coordinator`` set to `nil`.
@MainActor
public struct HierarchyNode {
    /// How the owner displays this destination.
    public let role: HierarchyRole

    /// The destination's route case, without its payload.
    public let meta: any DestinationMeta

    /// The child coordinator, or `nil` for a view route or a child not yet created.
    public let coordinator: (any Coordinatable)?

    /// Whether the route builds a child coordinator, created or not.
    public let hasCoordinator: Bool

    /// The child coordinator's destinations, recursively. Empty for a view route.
    public let children: [HierarchyNode]

    /// The case as ``Coordinatable/debugHierarchy()`` prints it, such as `.detail`.
    public var metaDescription: String {
        ".\(String(describing: meta))"
    }
}

@MainActor
public extension Coordinatable {
    /// Returns this coordinator's destinations as a tree of ``HierarchyNode`` values.
    ///
    /// This is the structured form of ``debugHierarchy()``, for tests and
    /// debug UIs:
    ///
    /// ```swift
    /// let pushed = coordinator.hierarchySnapshot().filter { $0.role == .push }
    /// ```
    ///
    /// The root, tabs, or columns come first, then pushes and modals in order.
    /// Taking a snapshot runs no route factories and creates no coordinators.
    /// A container that has not resolved its initial destinations returns an
    /// empty array; in tests, call `activated()` first. See <doc:Orientation>.
    func hierarchySnapshot() -> [HierarchyNode] {
        if let flow = self as? any FlowCoordinatable {
            var nodes: [HierarchyNode] = []
            if let root = flow._stack.root {
                nodes.append(_node(for: root, role: .root))
            }
            for destination in flow._stack.destinations {
                nodes.append(_node(for: destination, role: .init(destination.pushType)))
            }
            return nodes
        }

        if let tab = self as? any TabCoordinatable {
            let items = tab._tabItems
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
            if let rootDestination = root._root.root {
                nodes.append(_node(for: rootDestination, role: .root))
            }
            nodes += root._root.modals.map { _node(for: $0, role: .init($0.pushType)) }
            return nodes
        }

        if let split = self as? any SplitCoordinatable {
            let columns = split._columns
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
