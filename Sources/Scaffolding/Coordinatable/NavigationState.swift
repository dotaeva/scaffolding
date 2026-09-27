//
//  NavigationState.swift
//  Scaffolding
//
//  Created by Alexandr Valíček on 05.07.2026.
//

import SwiftUI

/// The encoded form of a captured coordinator subtree.
///
/// Capture methods write it into snapshot `Data`, and restore methods read it
/// back. Treat that data as opaque; you never create or inspect nodes.
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
    var hasContentColumn: Bool?
    var preferredCompactColumn: String?

    var schemaVersion: Int?
    var applicationVersion: Int?

    init() { }
}

/// Errors thrown when capturing or restoring navigation state.
public enum NavigationStateError: Error, CustomStringConvertible {
    /// The coordinator's `Destinations` is not `Codable`.
    ///
    /// Add `codable: true` to its `@Scaffoldable` attribute.
    case unsupported(coordinator: String)
    /// The snapshot uses a newer library schema than this version supports.
    case unsupportedVersion(Int)

    public var description: String {
        switch self {
        case .unsupportedVersion(let version):
            return "Scaffolding: unsupported navigation-state schema version \(version)."
        case .unsupported(let coordinator):
            return "Scaffolding: \(coordinator) cannot capture navigation state — its Destinations enum does not conform to Codable."
        }
    }
}

/// How a restore treats the navigation already on the coordinator.
public enum NavigationRestorationMode: Sendable {
    /// Adds the captured pushes and modals above the existing ones.
    case replay
    /// Removes existing pushes and modals first. Use it for seeded stacks and
    /// repeated restores.
    case replace
}

// MARK: - Public API

@MainActor
public extension Coordinatable {
    /// Captures the navigation of this coordinator and every child already
    /// created as opaque `Data`.
    ///
    /// Same as ``captureNavigationState(version:)`` with version `0`.
    ///
    /// ```swift
    /// let data = try appCoordinator.captureNavigationState()
    ///
    /// // Later, on a new coordinator:
    /// try AppCoordinator().restoreNavigationState(from: data, mode: .replace)
    /// ```
    ///
    /// The coordinator needs `@Scaffoldable(codable: true)`. Children without
    /// it are saved without their internal state and restore at their initial
    /// state. See <doc:StateRestoration>.
    ///
    /// - Throws: ``NavigationStateError/unsupported(coordinator:)`` when this
    ///   coordinator is not `Codable`, or the first route-encoding error.
    func captureNavigationState() throws -> Data {
        try captureNavigationState(version: 0)
    }

    /// Captures navigation as opaque `Data`, tagged with your snapshot version.
    ///
    /// Advance `version` when route payloads change, and upgrade older
    /// snapshots in the `migrate` hook of
    /// ``restoreNavigationStateWithReport(from:mode:migrate:)``. Children that
    /// are not `Codable` restore at their initial state.
    ///
    /// - Parameter version: Your application's snapshot version.
    /// - Throws: ``NavigationStateError/unsupported(coordinator:)`` when this
    ///   coordinator is not `Codable`, or the first route-encoding error.
    func captureNavigationState(version: Int) throws -> Data {
        let operation = NavigationStateOperation()
        let result = try captureState(version: version, operation: operation)
        if let error = operation.encodingError { throw error }
        return result.data
    }

    /// Captures a best-effort snapshot and reports what it left out.
    ///
    /// Routes that fail to encode are skipped and recorded in the report
    /// instead of throwing. Use ``captureNavigationState(version:)`` when a
    /// partial snapshot is unacceptable.
    ///
    /// - Parameter version: Your application's snapshot version.
    /// - Returns: The snapshot data and its ``NavigationStateReport``.
    /// - Throws: ``NavigationStateError/unsupported(coordinator:)`` when this
    ///   coordinator is not `Codable`.
    func captureNavigationStateWithReport(version: Int = 0) throws -> NavigationStateCapture {
        try captureState(version: version, operation: NavigationStateOperation())
    }

    private func captureState(version: Int, operation: NavigationStateOperation) throws -> NavigationStateCapture {
        try NavigationStateContext.$path.withValue([]) {
            try NavigationStateContext.$operation.withValue(operation) {
                guard let node = _captureNavigationStateNode() else {
                    throw NavigationStateError.unsupported(coordinator: String(describing: type(of: self)))
                }
                node.schemaVersion = 1
                node.applicationVersion = version
                return NavigationStateCapture(data: try JSONEncoder().encode(node), report: operation.report)
            }
        }
    }

    /// Restores a snapshot in ``NavigationRestorationMode/replay`` mode.
    ///
    /// Captured pushes and modals are added above the current state, so call
    /// it on a fresh coordinator. For seeded stacks or repeated restores, use
    /// ``restoreNavigationState(from:mode:)`` with `.replace`. Routes that no
    /// longer decode are skipped with their children.
    ///
    /// - Throws: A decoding error when `data` is not a snapshot, or
    ///   ``NavigationStateError/unsupportedVersion(_:)`` for a newer library schema.
    func restoreNavigationState(from data: Data) throws {
        try restoreNavigationState(from: data, mode: .replay)
    }

    /// Restores a snapshot using the given mode.
    ///
    /// Routes that no longer decode, or are unavailable on this OS, are
    /// skipped with their children. A child's saved state is never applied to
    /// a different route.
    ///
    /// - Parameters:
    ///   - data: A snapshot from a capture method.
    ///   - mode: `.replace` clears existing pushes and modals first;
    ///     `.replay` keeps them.
    /// - Throws: A decoding error when `data` is not a snapshot, or
    ///   ``NavigationStateError/unsupportedVersion(_:)`` for a newer library schema.
    func restoreNavigationState(from data: Data, mode: NavigationRestorationMode) throws {
        _ = try restoreNavigationStateWithReport(from: data, mode: mode)
    }

    /// Restores a snapshot and reports what was restored and skipped.
    ///
    /// `migrate` runs before full decoding and before any navigation changes.
    /// It receives the snapshot bytes and their application version (`0` when
    /// none was recorded). Return migrated bytes, or throw to leave the
    /// hierarchy untouched.
    ///
    /// ```swift
    /// let report = try app.restoreNavigationStateWithReport(from: data) { bytes, version in
    ///     try migrateNavigationSnapshot(bytes, from: version)  // your function
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - data: A snapshot from a capture method.
    ///   - mode: Defaults to `.replace`.
    ///   - migrate: An optional hook that upgrades older snapshots.
    /// - Returns: Route counts and any issues.
    /// - Throws: A decoding or migration error, or
    ///   ``NavigationStateError/unsupportedVersion(_:)``, before any change.
    func restoreNavigationStateWithReport(
        from data: Data,
        mode: NavigationRestorationMode = .replace,
        migrate: (@MainActor (Data, Int) throws -> Data)? = nil
    ) throws -> NavigationStateReport {
        let header = try JSONDecoder().decode(NavigationStateHeader.self, from: data)
        let migrated = try migrate?(data, header.applicationVersion ?? 0) ?? data
        let node = try JSONDecoder().decode(NavigationStateNode.self, from: migrated)
        guard (node.schemaVersion ?? 0) <= 1, (node.schemaVersion ?? 0) >= 0 else {
            throw NavigationStateError.unsupportedVersion(node.schemaVersion ?? 0)
        }
        let operation = NavigationStateOperation()
        NavigationStateContext.$path.withValue([]) {
            NavigationStateContext.$operation.withValue(operation) {
                NavigationStateContext.$mode.withValue(mode) {
                    _restoreNavigationStateNode(node)
                }
            }
        }
        return operation.report
    }
}

// MARK: - Default (unsupported) witnesses

@MainActor
public extension Coordinatable {
    func _captureNavigationStateNode() -> NavigationStateNode? {
        recordStateIssue(self, reason: .unsupportedCoordinator, message: "Destinations do not conform to Codable.")
        return nil
    }
    func _restoreNavigationStateNode(_ node: NavigationStateNode) {
        recordStateIssue(self, reason: .unsupportedCoordinator, message: "Destinations do not conform to Codable.")
    }
}

// MARK: - Capture and restoration by container

@MainActor
public extension FlowCoordinatable where Destinations: Codable {
    func _captureNavigationStateNode() -> NavigationStateNode? {
        let node = NavigationStateNode()
        if let root = _resolvedStack.root {
            node.rootRoute = encodeStateRoute(root, owner: self, at: "root")
            if node.rootRoute != nil { node.rootChild = captureStateChild(root, at: "root") }
        }
        node.entries = captureStateEntries(stack.destinations)
        return node
    }

    func _restoreNavigationStateNode(_ node: NavigationStateNode) {
        _ = _resolvedStack
        if NavigationStateContext.mode == .replace { popToRoot() }
        if let data = node.rootRoute, let route = decodeStateRoute(data, owner: self, at: "root") {
            if !_sameRoute(stack.root?.source as? Destinations, route) ||
                needsInitialState(stack.root, savedChild: node.rootChild) {
                setRoot(route)
            }
            didRestoreStateRoute()
            restoreStateChild(node.rootChild, into: stack.root, at: "root")
        }
        for (index, entry) in node.entries.enumerated() {
            let location = "entries[\(index)]"
            guard let route = decodeStateRoute(entry.route, owner: self, at: location) else { continue }
            let destination = performRoute(to: route, as: entry.presentation.presentationType, onDismiss: {})
            didRestoreStateRoute()
            restoreStateChild(entry.child, into: destination, at: location)
        }
    }
}

@MainActor
public extension RootCoordinatable where Destinations: Codable {
    func _captureNavigationStateNode() -> NavigationStateNode? {
        let node = NavigationStateNode()
        if let root = _resolvedRoot.root {
            node.rootRoute = encodeStateRoute(root, owner: self, at: "root")
            if node.rootRoute != nil { node.rootChild = captureStateChild(root, at: "root") }
        }
        node.entries = captureStateEntries(root.modals)
        return node
    }

    func _restoreNavigationStateNode(_ node: NavigationStateNode) {
        _ = _resolvedRoot
        if NavigationStateContext.mode == .replace { dismissAllModals() }
        if let data = node.rootRoute, let route = decodeStateRoute(data, owner: self, at: "root") {
            if !_sameRoute(root.root?.source as? Destinations, route) ||
                needsInitialState(root.root, savedChild: node.rootChild) {
                setRoot(route)
            }
            didRestoreStateRoute()
            restoreStateChild(node.rootChild, into: root.root, at: "root")
        }
        restoreStateModals(node.entries)
    }
}

@MainActor
public extension TabCoordinatable where Destinations: Codable {
    func _captureNavigationStateNode() -> NavigationStateNode? {
        let node = NavigationStateNode()
        let items = _resolvedTabItems
        var routes: [Data] = []
        var children: [NavigationStateNode?] = []
        for (index, destination) in items.tabs.enumerated() {
            let location = "tabs[\(index)]"
            guard let data = encodeStateRoute(destination, owner: self, at: location) else { continue }
            if destination.id == items.selectedTab { node.selectedIndex = routes.count }
            routes.append(data)
            children.append(captureStateChild(destination, at: location))
        }
        node.tabRoutes = routes
        node.tabChildren = children
        node.entries = captureStateEntries(items.modals)
        return node
    }

    func _restoreNavigationStateNode(_ node: NavigationStateNode) {
        let items = _resolvedTabItems
        if NavigationStateContext.mode == .replace { dismissAllModals() }
        if let routes = node.tabRoutes {
            let decoded = routes.enumerated().compactMap { decodeStateRoute($0.element, owner: self, at: "tabs[\($0.offset)]") }
            // Keep the tab set atomic: never apply a child snapshot to a different tab.
            if decoded.count == routes.count {
                let unchanged = decoded.count == items.tabs.count && zip(items.tabs, decoded).allSatisfy {
                    _sameRoute($0.0.source as? Destinations, $0.1)
                }
                if !unchanged {
                    setTabs(decoded)
                } else {
                    var tabs = items.tabs
                    var replaced = false
                    for index in decoded.indices {
                        let child = index < node.tabChildren.count ? node.tabChildren[index] : nil
                        guard needsInitialState(tabs[index], savedChild: child) else { continue }
                        let destination = decoded[index].resolvedValue(for: self)
                        destination.coordinatable?.attach(
                            to: self, navigationLayer: hasLayerNavigationCoordinatable,
                            presentation: items.presentedAs
                        )
                        tabs[index] = destination
                        replaced = true
                    }
                    if replaced { tabItems.setTabs(tabs) }
                }
                for index in decoded.indices {
                    didRestoreStateRoute()
                    let child = index < node.tabChildren.count ? node.tabChildren[index] : nil
                    restoreStateChild(child, into: items.tabs[index], at: "tabs[\(index)]")
                }
                if let selected = node.selectedIndex { select(index: selected) }
            } else {
                recordStateIssue(self, at: "tabs", reason: .invalidTabSet, message: "Kept the current tab set because one or more saved routes could not be restored.", skipped: decoded.count)
            }
        }
        restoreStateModals(node.entries)
    }
}

@MainActor
public extension SplitCoordinatable where Destinations: Codable {
    func _captureNavigationStateNode() -> NavigationStateNode? {
        let node = NavigationStateNode()
        let items = _resolvedSplitColumns
        if let destination = items.sidebar {
            node.sidebarRoute = encodeStateRoute(destination, owner: self, at: "sidebar")
            if node.sidebarRoute != nil { node.sidebarChild = captureStateChild(destination, at: "sidebar") }
        }
        if let destination = items.content {
            node.contentRoute = encodeStateRoute(destination, owner: self, at: "content")
            if node.contentRoute != nil { node.contentChild = captureStateChild(destination, at: "content") }
        }
        if let destination = items.detail {
            node.detailRoute = encodeStateRoute(destination, owner: self, at: "detail")
            if node.detailRoute != nil { node.detailChild = captureStateChild(destination, at: "detail") }
        }
        node.splitVisibility = _encodeSplitVisibility(items.columnVisibility)
        node.hasContentColumn = items.hasContentColumn
        switch items.preferredCompactColumn {
        case .sidebar: node.preferredCompactColumn = "sidebar"
        case .content: node.preferredCompactColumn = "content"
        case .detail: node.preferredCompactColumn = "detail"
        default: break
        }
        node.entries = captureStateEntries(items.modals)
        return node
    }

    func _restoreNavigationStateNode(_ node: NavigationStateNode) {
        _ = _resolvedSplitColumns
        if NavigationStateContext.mode == .replace { dismissAllModals() }
        restoreStateColumn(.sidebar, route: node.sidebarRoute, child: node.sidebarChild)
        if node.hasContentColumn == false { removeContent() }
        else { restoreStateColumn(.content, route: node.contentRoute, child: node.contentChild) }
        restoreStateColumn(.detail, route: node.detailRoute, child: node.detailChild)
        switch node.preferredCompactColumn {
        case "sidebar": setPreferredCompactColumn(.sidebar)
        case "content": setPreferredCompactColumn(.content)
        case "detail": setPreferredCompactColumn(.detail)
        default: break
        }
        if let visibility = node.splitVisibility.flatMap(_decodeSplitVisibility) { setColumnVisibility(visibility) }
        restoreStateModals(node.entries)
    }

    private func restoreStateColumn(_ column: SplitColumn, route: Data?, child: NavigationStateNode?) {
        guard let route, let decoded = decodeStateRoute(route, owner: self, at: column.rawValue) else { return }
        if !_sameRoute(columns.destination(for: column)?.source as? Destinations, decoded) ||
            needsInitialState(columns.destination(for: column), savedChild: child) {
            _ = performSetColumn(column, to: decoded)
        }
        didRestoreStateRoute()
        restoreStateChild(child, into: columns.destination(for: column), at: column.rawValue)
    }
}

@MainActor
private extension Coordinatable where Destinations: Codable {
    func captureStateEntries(_ destinations: [Destination]) -> [NavigationStateNode.Entry] {
        destinations.enumerated().compactMap { index, destination in
            let location = "entries[\(index)]"
            guard let data = encodeStateRoute(destination, owner: self, at: location),
                  let presentation = NavigationStateNode.Presentation(destination.pushType) else { return nil }
            return .init(route: data, presentation: presentation, child: captureStateChild(destination, at: location))
        }
    }

    func restoreStateModals(_ entries: [NavigationStateNode.Entry]) {
        for (index, entry) in entries.enumerated() {
            let location = "entries[\(index)]"
            guard let route = decodeStateRoute(entry.route, owner: self, at: location),
                  let destination = makeModal(route, as: entry.presentation.modalType, policy: .always) else { continue }
            didRestoreStateRoute()
            restoreStateChild(entry.child, into: destination, at: location)
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

/// A missing child snapshot means the route factory supplies its initial state.
/// Reusing a live child during replacement would retain navigation that was
/// never captured. Replay deliberately keeps that existing state.
@MainActor
private func needsInitialState(_ destination: Destination?, savedChild: NavigationStateNode?) -> Bool {
    NavigationStateContext.mode == .replace && savedChild == nil && destination?.hasCoordinatable == true
}

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

/// Compare payloads as well as cases, without requiring user routes to be Equatable.
private func _sameRoute<Route: Encodable>(_ current: Route?, _ restored: Route) -> Bool {
    guard let current else { return false }
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    guard let left = try? encoder.encode(current), let right = try? encoder.encode(restored) else { return false }
    return left == right
}

private struct NavigationStateHeader: Decodable { var applicationVersion: Int? }
