//
//  NavigationState.swift
//  Scaffolding
//
//  Created by Alexandr Valíček on 05.07.2026.
//

import SwiftUI

/// A codable snapshot of a coordinator subtree.
///
/// Produced by ``Coordinatable/captureNavigationState()`` and consumed by
/// ``Coordinatable/restoreNavigationState(from:)``. You never build these
/// yourself — treat the encoded `Data` as opaque.
public final class NavigationStateNode: Codable {
    /// How a captured destination was presented.
    enum Presentation: String, Codable, Sendable {
        case push
        case sheet
        case fullScreenCover
    }

    /// A captured destination: its encoded route, how it was presented,
    /// and the state of its child coordinator, if one was created.
    struct Entry: Codable {
        var route: Data
        var presentation: Presentation
        var child: NavigationStateNode?
    }

    /// The encoded route of the root destination (flow and root
    /// coordinators).
    var rootRoute: Data?
    /// The captured state of the root destination's child coordinator.
    var rootChild: NavigationStateNode?
    /// Pushed and presented destinations (flow), or presented modals
    /// (root and tab coordinators).
    var entries: [Entry] = []
    /// The encoded routes of the current tabs (tab coordinators).
    var tabRoutes: [Data]?
    /// The index of the selected tab (tab coordinators).
    var selectedIndex: Int?
    /// Captured state of each tab's child coordinator, aligned with
    /// ``tabRoutes`` (tab coordinators).
    var tabChildren: [NavigationStateNode?] = []

    /// The encoded routes of the split-view columns (split coordinators).
    /// All optional so snapshots taken by older versions keep decoding.
    var sidebarRoute: Data?
    var contentRoute: Data?
    var detailRoute: Data?
    /// Captured state of each column's child coordinator (split
    /// coordinators).
    var sidebarChild: NavigationStateNode?
    var contentChild: NavigationStateNode?
    var detailChild: NavigationStateNode?
    /// The captured column visibility (split coordinators).
    var splitVisibility: String?

    init() { }
}

/// Errors thrown by the navigation-state APIs.
public enum NavigationStateError: Error, CustomStringConvertible {
    /// The coordinator's `Destinations` do not conform to `Codable`, so
    /// its state cannot be captured.
    case unsupported(coordinator: String)

    public var description: String {
        switch self {
        case .unsupported(let coordinator):
            return "Scaffolding: \(coordinator) cannot capture navigation state — its Destinations enum does not conform to Codable."
        }
    }
}

// MARK: - Public API

@MainActor
public extension Coordinatable {
    /// Captures the navigation state of this coordinator and every
    /// already-created descendant as opaque `Data`.
    ///
    /// Persist the data (e.g. in `SceneStorage` or a file) and feed it to
    /// ``restoreNavigationState(from:)`` on a freshly created coordinator
    /// of the same type to return the user to where they left off:
    ///
    /// ```swift
    /// // On background
    /// let data = try appCoordinator.captureNavigationState()
    ///
    /// // On cold launch
    /// let appCoordinator = AppCoordinator()
    /// try appCoordinator.restoreNavigationState(from: data)
    /// ```
    ///
    /// Requires the coordinator's `Destinations` enum to conform to
    /// `Codable` — with the ``Scaffoldable(injectsCoordinator:codable:)``
    /// macro, pass `codable: true` and make sure every route's associated
    /// values are `Codable`. Subtrees whose coordinators do not support
    /// capture are recorded without their internal state and restore at
    /// their initial position.
    ///
    /// - Throws: ``NavigationStateError/unsupported(coordinator:)`` when
    ///   this coordinator itself cannot be captured, or an encoding error.
    func captureNavigationState() throws -> Data {
        guard let node = _captureNavigationStateNode() else {
            throw NavigationStateError.unsupported(
                coordinator: String(describing: type(of: self))
            )
        }
        return try JSONEncoder().encode(node)
    }

    /// Restores navigation state previously captured with
    /// ``captureNavigationState()``.
    ///
    /// Call this on a freshly created coordinator — restoration replays
    /// the captured routes on top of the coordinator's initial state.
    /// Routes that fail to decode (e.g. after the `Destinations` enum
    /// changed shape between app versions) are skipped, so a stale
    /// snapshot degrades gracefully instead of failing the launch.
    ///
    /// - Throws: A decoding error when the data itself is not a valid
    ///   navigation-state snapshot.
    func restoreNavigationState(from data: Data) throws {
        let node = try JSONDecoder().decode(NavigationStateNode.self, from: data)
        _restoreNavigationStateNode(node)
    }
}

// MARK: - Default (unsupported) witnesses

@MainActor
public extension Coordinatable {
    func _captureNavigationStateNode() -> NavigationStateNode? { nil }
    func _restoreNavigationStateNode(_ node: NavigationStateNode) { }
}

// MARK: - FlowCoordinatable

@MainActor
public extension FlowCoordinatable where Destinations: Codable {
    func _captureNavigationStateNode() -> NavigationStateNode? {
        let node = NavigationStateNode()
        let encoder = JSONEncoder()

        if let root = anyStack.root {
            if let source = root.source as? Destinations {
                node.rootRoute = try? encoder.encode(source)
            }
            node.rootChild = root.materializedCoordinatable?._captureNavigationStateNode()
        }

        for destination in stack.destinations {
            guard let source = destination.source as? Destinations,
                  let route = try? encoder.encode(source),
                  let presentation = NavigationStateNode.Presentation(destination.pushType)
            else { continue }

            node.entries.append(.init(
                route: route,
                presentation: presentation,
                child: destination.materializedCoordinatable?._captureNavigationStateNode()
            ))
        }

        return node
    }

    func _restoreNavigationStateNode(_ node: NavigationStateNode) {
        _ = anyStack // ensure setup
        let decoder = JSONDecoder()

        if let rootData = node.rootRoute,
           let rootRoute = try? decoder.decode(Destinations.self, from: rootData) {
            let currentMeta = anyStack.root?.meta as? Destinations.Meta
            if currentMeta != rootRoute.meta {
                setRoot(rootRoute, animation: nil)
            }
        }
        if let rootChild = node.rootChild {
            anyStack.root?.coordinatable?._restoreNavigationStateNode(rootChild)
        }

        for entry in node.entries {
            guard let route = try? decoder.decode(Destinations.self, from: entry.route) else { continue }
            let destination = performRoute(
                to: route,
                as: entry.presentation.presentationType,
                onDismiss: { }
            )
            if let child = entry.child {
                destination.coordinatable?._restoreNavigationStateNode(child)
            }
        }
    }
}

// MARK: - RootCoordinatable

@MainActor
public extension RootCoordinatable where Destinations: Codable {
    func _captureNavigationStateNode() -> NavigationStateNode? {
        let node = NavigationStateNode()
        let encoder = JSONEncoder()

        if let rootDestination = anyRoot.root {
            if let source = rootDestination.source as? Destinations {
                node.rootRoute = try? encoder.encode(source)
            }
            node.rootChild = rootDestination.materializedCoordinatable?._captureNavigationStateNode()
        }

        node.entries = anyRoot.modals.compactMap { destination in
            guard let source = destination.source as? Destinations,
                  let route = try? encoder.encode(source),
                  let presentation = NavigationStateNode.Presentation(destination.pushType)
            else { return nil }
            return .init(
                route: route,
                presentation: presentation,
                child: destination.materializedCoordinatable?._captureNavigationStateNode()
            )
        }

        return node
    }

    func _restoreNavigationStateNode(_ node: NavigationStateNode) {
        _ = anyRoot // ensure setup
        let decoder = JSONDecoder()

        if let rootData = node.rootRoute,
           let rootRoute = try? decoder.decode(Destinations.self, from: rootData) {
            let currentMeta = anyRoot.root?.meta as? Destinations.Meta
            if currentMeta != rootRoute.meta {
                setRoot(rootRoute, animation: nil)
            }
        }
        if let rootChild = node.rootChild {
            anyRoot.root?.coordinatable?._restoreNavigationStateNode(rootChild)
        }

        restoreModalEntries(node.entries, using: decoder)
    }
}

// MARK: - TabCoordinatable

@MainActor
public extension TabCoordinatable where Destinations: Codable {
    func _captureNavigationStateNode() -> NavigationStateNode? {
        let node = NavigationStateNode()
        let encoder = JSONEncoder()

        let items = anyTabItems
        node.tabRoutes = items.tabs.map { destination in
            guard let source = destination.source as? Destinations else { return Data() }
            return (try? encoder.encode(source)) ?? Data()
        }
        node.selectedIndex = items.tabs.firstIndex { $0.id == items.selectedTab }
        node.tabChildren = items.tabs.map {
            $0.materializedCoordinatable?._captureNavigationStateNode()
        }

        node.entries = items.modals.compactMap { destination in
            guard let source = destination.source as? Destinations,
                  let route = try? encoder.encode(source),
                  let presentation = NavigationStateNode.Presentation(destination.pushType)
            else { return nil }
            return .init(
                route: route,
                presentation: presentation,
                child: destination.materializedCoordinatable?._captureNavigationStateNode()
            )
        }

        return node
    }

    func _restoreNavigationStateNode(_ node: NavigationStateNode) {
        let items = anyTabItems // ensure setup
        let decoder = JSONDecoder()

        // Re-apply a dynamically changed tab set when the captured routes
        // decode and differ from the current tabs.
        if let tabRoutes = node.tabRoutes {
            let decoded = tabRoutes.compactMap { try? decoder.decode(Destinations.self, from: $0) }
            if decoded.count == tabRoutes.count {
                let currentMetas = items.tabs.compactMap { $0.meta as? Destinations.Meta }
                if decoded.map(\.meta) != currentMetas {
                    setTabs(decoded)
                }
            }
        }

        for (index, child) in node.tabChildren.enumerated() {
            guard let child, index < anyTabItems.tabs.count else { continue }
            anyTabItems.tabs[index].coordinatable?._restoreNavigationStateNode(child)
        }

        if let selectedIndex = node.selectedIndex {
            select(index: selectedIndex)
        }

        restoreModalEntries(node.entries, using: decoder)
    }
}

// MARK: - SplitCoordinatable

@MainActor
public extension SplitCoordinatable where Destinations: Codable {
    func _captureNavigationStateNode() -> NavigationStateNode? {
        let node = NavigationStateNode()
        let encoder = JSONEncoder()
        let items = anySplitColumns

        if let sidebar = items.sidebar {
            if let source = sidebar.source as? Destinations {
                node.sidebarRoute = try? encoder.encode(source)
            }
            node.sidebarChild = sidebar.materializedCoordinatable?._captureNavigationStateNode()
        }
        if let content = items.content {
            if let source = content.source as? Destinations {
                node.contentRoute = try? encoder.encode(source)
            }
            node.contentChild = content.materializedCoordinatable?._captureNavigationStateNode()
        }
        if let detail = items.detail {
            if let source = detail.source as? Destinations {
                node.detailRoute = try? encoder.encode(source)
            }
            node.detailChild = detail.materializedCoordinatable?._captureNavigationStateNode()
        }

        node.splitVisibility = _encodeSplitVisibility(items.columnVisibility)

        node.entries = items.modals.compactMap { destination in
            guard let source = destination.source as? Destinations,
                  let route = try? encoder.encode(source),
                  let presentation = NavigationStateNode.Presentation(destination.pushType)
            else { return nil }
            return .init(
                route: route,
                presentation: presentation,
                child: destination.materializedCoordinatable?._captureNavigationStateNode()
            )
        }

        return node
    }

    func _restoreNavigationStateNode(_ node: NavigationStateNode) {
        _ = anySplitColumns // ensure setup
        let decoder = JSONDecoder()

        restoreColumn(.sidebar, route: node.sidebarRoute, child: node.sidebarChild, using: decoder)
        restoreColumn(.content, route: node.contentRoute, child: node.contentChild, using: decoder)
        restoreColumn(.detail, route: node.detailRoute, child: node.detailChild, using: decoder)

        if let visibility = node.splitVisibility.flatMap(_decodeSplitVisibility) {
            anySplitColumns.columnVisibility = visibility
        }

        restoreModalEntries(node.entries, using: decoder)
    }
}

@MainActor
private extension SplitCoordinatable where Destinations: Codable {
    func restoreColumn(
        _ column: SplitColumn,
        route: Data?,
        child: NavigationStateNode?,
        using decoder: JSONDecoder
    ) {
        if let route,
           let decoded = try? decoder.decode(Destinations.self, from: route) {
            let currentMeta = columns.destination(for: column)?.meta as? Destinations.Meta
            if currentMeta != decoded.meta {
                _ = performSetColumn(column, to: decoded)
            }
        }
        if let child {
            columns.destination(for: column)?.coordinatable?._restoreNavigationStateNode(child)
        }
    }

    func restoreModalEntries(_ entries: [NavigationStateNode.Entry], using decoder: JSONDecoder) {
        for entry in entries {
            guard let route = try? decoder.decode(Destinations.self, from: entry.route) else { continue }
            let destination = performPresent(route, as: entry.presentation.modalType, onDismiss: { })
            if let child = entry.child {
                destination.coordinatable?._restoreNavigationStateNode(child)
            }
        }
    }
}

/// `NavigationSplitViewVisibility` is not `Codable` — round-trip the known
/// values through a stable string.
@MainActor
private func _encodeSplitVisibility(_ visibility: NavigationSplitViewVisibility) -> String? {
    switch visibility {
    case .automatic: return "automatic"
    case .all: return "all"
    case .doubleColumn: return "doubleColumn"
    case .detailOnly: return "detailOnly"
    default: return nil
    }
}

@MainActor
private func _decodeSplitVisibility(_ value: String) -> NavigationSplitViewVisibility? {
    switch value {
    case "automatic": return .automatic
    case "all": return .all
    case "doubleColumn": return .doubleColumn
    case "detailOnly": return .detailOnly
    default: return nil
    }
}

// MARK: - Shared helpers

extension NavigationStateNode.Presentation {
    @MainActor
    init?(_ pushType: PresentationType?) {
        switch pushType {
        case .push: self = .push
        case .sheet: self = .sheet
        case .fullScreenCover: self = .fullScreenCover
        case nil: return nil
        }
    }

    @MainActor
    var presentationType: PresentationType {
        switch self {
        case .push: return .push
        case .sheet: return .sheet
        case .fullScreenCover: return .fullScreenCover
        }
    }

    @MainActor
    var modalType: ModalPresentationType {
        switch self {
        case .fullScreenCover: return .fullScreenCover
        case .push, .sheet: return .sheet
        }
    }
}

@MainActor
private extension RootCoordinatable where Destinations: Codable {
    func restoreModalEntries(_ entries: [NavigationStateNode.Entry], using decoder: JSONDecoder) {
        for entry in entries {
            guard let route = try? decoder.decode(Destinations.self, from: entry.route) else { continue }
            let destination = performPresent(route, as: entry.presentation.modalType, onDismiss: { })
            if let child = entry.child {
                destination.coordinatable?._restoreNavigationStateNode(child)
            }
        }
    }
}

@MainActor
private extension TabCoordinatable where Destinations: Codable {
    func restoreModalEntries(_ entries: [NavigationStateNode.Entry], using decoder: JSONDecoder) {
        for entry in entries {
            guard let route = try? decoder.decode(Destinations.self, from: entry.route) else { continue }
            let destination = performPresent(route, as: entry.presentation.modalType, onDismiss: { })
            if let child = entry.child {
                destination.coordinatable?._restoreNavigationStateNode(child)
            }
        }
    }
}
