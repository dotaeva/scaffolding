//
//  SplitColumns.swift
//  Scaffolding
//
//  Created by Alexandr Valíček on 21.08.2026.
//

import SwiftUI
import Observation

/// A column of a ``SplitCoordinatable``'s `NavigationSplitView`.
public enum SplitColumn: String, Equatable, Hashable, Sendable {
    /// The leading column.
    case sidebar
    /// The optional middle column of a three-column split view.
    case content
    /// The trailing column.
    case detail
}

/// A type-erased protocol for ``SplitColumns`` that allows the framework
/// to manipulate split-view state without knowing the concrete coordinator
/// type.
@MainActor
public protocol AnySplitColumns: AnyObject, CoordinatableData where Coordinator: SplitCoordinatable {
    /// The resolved sidebar destination.
    var sidebar: Destination? { get set }
    /// The resolved content destination (three-column split views only).
    var content: Destination? { get set }
    /// The resolved detail destination.
    var detail: Destination? { get set }
    /// Whether a content column is currently present.
    var hasContentColumn: Bool { get }
    /// The visibility of the split view's leading columns.
    var columnVisibility: NavigationSplitViewVisibility { get set }
    /// The column shown when the split view collapses to a single column.
    var preferredCompactColumn: NavigationSplitViewColumn { get set }
    /// The presentation type if this split coordinator was presented modally.
    var presentedAs: PresentationType? { get set }
    /// Modal destinations presented from this coordinator.
    var modals: [Destination] { get set }
}

/// Observable state container for a ``SplitCoordinatable`` coordinator.
///
/// `SplitColumns` holds one destination per column of a
/// `NavigationSplitView` — sidebar, optional content, and detail — plus
/// the column visibility. Column assignment happens here, in the
/// initializer, so route functions keep the plain auto-tracked return
/// types (`some View` / `any Coordinatable`):
///
/// ```swift
/// var columns = SplitColumns<LibraryCoordinator>(
///     sidebar: .sidebar,
///     detail: .placeholder
/// )
/// ```
@MainActor
@Observable
public class SplitColumns<Coordinator: SplitCoordinatable>: AnySplitColumns {
    /// The parent coordinator that owns this split coordinator, if any.
    public weak var parent: (any Coordinatable)?
    /// Whether a parent flow coordinator provides the navigation layer.
    public var hasLayerNavigationCoordinator: Bool = false
    /// The presentation type when this coordinator was presented modally.
    public var presentedAs: PresentationType?
    /// Modal destinations presented from this coordinator.
    public var modals: [Destination] = []

    /// The resolved sidebar destination.
    public var sidebar: Destination?
    /// The resolved content destination (three-column split views only).
    public var content: Destination?
    /// The resolved detail destination.
    public var detail: Destination?

    /// The visibility of the split view's leading columns.
    public var columnVisibility: NavigationSplitViewVisibility
    /// The column shown when the split view collapses to a single column.
    public var preferredCompactColumn: NavigationSplitViewColumn

    /// Whether a content column is currently present.
    ///
    /// The three-column initializer seeds one;
    /// ``SplitCoordinatable/setContent(_:policy:)`` installs one at
    /// runtime and ``SplitCoordinatable/removeContent()`` drops it. The
    /// rendered container swaps between `NavigationSplitView`'s two- and
    /// three-column forms when this changes.
    public var hasContentColumn: Bool { content != nil || initialContent != nil }

    /// Whether ``setup(for:)`` has been called.
    public var isSetup: Bool = false
    private var initialSidebar: Coordinator.Destinations?
    private var initialContent: Coordinator.Destinations?
    private var initialDetail: Coordinator.Destinations?
    private var coordinator: Coordinator?

    /// Creates a two-column split container.
    ///
    /// - Parameters:
    ///   - sidebar: The destination shown in the leading column.
    ///   - detail: The destination shown in the detail column before any
    ///     selection — typically a placeholder.
    ///   - visibility: The initial column visibility.
    ///   - preferredCompactColumn: The column shown when the split view
    ///     collapses to a single column (compact width).
    public init(
        sidebar: Coordinator.Destinations,
        detail: Coordinator.Destinations,
        visibility: NavigationSplitViewVisibility = .automatic,
        preferredCompactColumn: NavigationSplitViewColumn = .sidebar
    ) {
        self.initialSidebar = sidebar
        self.initialDetail = detail
        self.columnVisibility = visibility
        self.preferredCompactColumn = preferredCompactColumn
    }

    /// Creates a three-column split container.
    ///
    /// - Parameters:
    ///   - sidebar: The destination shown in the leading column.
    ///   - content: The destination shown in the middle column.
    ///   - detail: The destination shown in the detail column before any
    ///     selection — typically a placeholder.
    ///   - visibility: The initial column visibility.
    ///   - preferredCompactColumn: The column shown when the split view
    ///     collapses to a single column (compact width).
    public init(
        sidebar: Coordinator.Destinations,
        content: Coordinator.Destinations,
        detail: Coordinator.Destinations,
        visibility: NavigationSplitViewVisibility = .automatic,
        preferredCompactColumn: NavigationSplitViewColumn = .sidebar
    ) {
        self.initialSidebar = sidebar
        self.initialContent = content
        self.initialDetail = detail
        self.columnVisibility = visibility
        self.preferredCompactColumn = preferredCompactColumn
    }

    /// Performs one-time setup, resolving the initial column destinations.
    ///
    /// - Parameter coordinator: The coordinator that owns this container.
    public func setup(for coordinator: Coordinator) {
        guard !isSetup else { return }
        self.coordinator = coordinator

        if let initialSidebar, sidebar == nil {
            sidebar = resolve(initialSidebar, as: .sidebar, for: coordinator)
        }
        if let initialContent, content == nil {
            content = resolve(initialContent, as: .content, for: coordinator)
        }
        if let initialDetail, detail == nil {
            detail = resolve(initialDetail, as: .detail, for: coordinator)
        }
        initialSidebar = nil
        initialContent = nil
        initialDetail = nil

        self.isSetup = true
    }

    /// Sets the parent coordinator reference.
    public func setParent(_ parent: any Coordinatable) {
        self.parent = parent
    }

    private func resolve(
        _ destination: Coordinator.Destinations,
        as column: SplitColumn,
        for coordinator: Coordinator
    ) -> Destination {
        var dest = destination.resolvedValue(for: coordinator)
        dest.setColumn(column)
        // Each column provides its own navigation layer inside the split
        // view — a child flow builds its own NavigationStack there.
        dest.coordinatable?.setHasLayerNavigationCoordinatable(false)
        dest.coordinatable?.setParent(coordinator)

        if let presentedAs {
            dest.setPushType(presentedAs)
            propagateDestinationType(to: dest.coordinatable, as: presentedAs)
        }

        return dest
    }

    private func propagateDestinationType(to coordinatable: (any Coordinatable)?, as type: PresentationType) {
        guard let coordinatable = coordinatable else { return }

        if let flowCoordinator = coordinatable as? any FlowCoordinatable {
            flowCoordinator.setPresentedAs(type)
        } else if let tabCoordinator = coordinatable as? any TabCoordinatable {
            tabCoordinator.setPresentedAs(type)
        } else if let rootCoordinator = coordinatable as? any RootCoordinatable {
            rootCoordinator.setPresentedAs(type)
        } else if let splitCoordinator = coordinatable as? any SplitCoordinatable {
            splitCoordinator.setPresentedAs(type)
        }
    }
}

extension SplitColumns {
    /// Replaces the destination shown in the given column, resolving the
    /// dismissal of the previous one exactly once.
    func replace(_ column: SplitColumn, with destination: Destination) -> Destination {
        var dest = destination
        dest.setColumn(column)
        dest.coordinatable?.setHasLayerNavigationCoordinatable(false)
        if let coordinator {
            dest.coordinatable?.setParent(coordinator)
        }
        if let presentedAs, dest.pushType == nil {
            dest.setPushType(presentedAs)
            propagateDestinationType(to: dest.coordinatable, as: presentedAs)
        }

        let previous: Destination?
        switch column {
        case .sidebar:
            previous = sidebar
            sidebar = dest
        case .content:
            previous = content
            content = dest
        case .detail:
            previous = detail
            detail = dest
        }
        previous?.resolveDismissal()
        return dest
    }

    /// The destination currently shown in the given column, if any.
    func destination(for column: SplitColumn) -> Destination? {
        switch column {
        case .sidebar: return sidebar
        case .content: return content
        case .detail: return detail
        }
    }

    /// Drops the content column, resolving the dismissal of its
    /// destination exactly once. The container swaps back to the
    /// two-column form.
    func removeContent() {
        initialContent = nil
        let previous = content
        content = nil
        previous?.resolveDismissal()
    }
}
