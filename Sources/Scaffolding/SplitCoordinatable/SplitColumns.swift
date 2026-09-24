//
//  SplitColumns.swift
//  Scaffolding
//
//  Created by Alexandr Valíček on 21.08.2026.
//

import SwiftUI
import Observation

/// A column of a ``SplitCoordinatable``.
///
/// Read a view's column from `@Environment(\.destination).column`.
public enum SplitColumn: String, Equatable, Hashable, Sendable {
    /// The leading column.
    case sidebar
    /// The optional middle column.
    case content
    /// The trailing column.
    case detail
}

/// Read-only, type-erased access to a ``SplitColumns`` container.
///
/// Change columns and layout through the owning coordinator.
@MainActor
public protocol AnySplitColumns: AnyObject, CoordinatableData where Coordinator: SplitCoordinatable {
    /// The sidebar destination.
    var sidebar: Destination? { get }
    /// The content destination, or `nil` for a two-column split.
    var content: Destination? { get }
    /// The detail destination.
    var detail: Destination? { get }
    /// Whether the split has a content column.
    var hasContentColumn: Bool { get }
    /// The requested column visibility.
    var columnVisibility: NavigationSplitViewVisibility { get }
    /// The column shown at compact width.
    var preferredCompactColumn: NavigationSplitViewColumn { get }
    /// How this coordinator was presented, or `nil` when it isn't modal.
    var presentedAs: PresentationType? { get }
    /// This coordinator's modal requests; the first is visible.
    var modals: [Destination] { get }
}

/// The state container of a ``SplitCoordinatable``: one destination per
/// column, the column layout, and modal requests.
///
/// Assign the initial columns here, so routes keep their ordinary return
/// types:
///
/// ```swift
/// var columns = SplitColumns<LibraryCoordinator>(
///     sidebar: .sidebar,
///     detail: .placeholder
/// )
/// ```
///
/// Properties are readable; change them through the coordinator's methods.
@MainActor
@Observable
public class SplitColumns<Coordinator: SplitCoordinatable>: AnySplitColumns {
    /// The coordinator hosting this split, or `nil` at the top level.
    public internal(set) weak var parent: (any Coordinatable)?
    /// Whether an enclosing flow provides the navigation stack.
    public internal(set) var hasLayerNavigationCoordinator: Bool = false
    /// How this coordinator was presented, or `nil` when it isn't modal.
    public internal(set) var presentedAs: PresentationType?
    /// This coordinator's modal requests; the first is visible, the rest wait.
    public internal(set) var modals: [Destination] = []

    /// The sidebar destination.
    public internal(set) var sidebar: Destination?
    /// The content destination, or `nil` for a two-column split.
    public internal(set) var content: Destination?
    /// The detail destination.
    public internal(set) var detail: Destination?

    /// The requested column visibility, including user changes.
    public internal(set) var columnVisibility: NavigationSplitViewVisibility
    /// The column shown when the split collapses at compact width.
    public internal(set) var preferredCompactColumn: NavigationSplitViewColumn

    /// Whether the split has a content column.
    ///
    /// The three-column initializer adds one,
    /// ``SplitCoordinatable/setContent(_:policy:)`` adds one at runtime, and
    /// ``SplitCoordinatable/removeContent()`` removes it.
    public var hasContentColumn: Bool { content != nil || initialContent != nil }

    /// The default animation for navigation changes. Set it with
    /// ``SplitCoordinatable/setTransitionAnimation(_:)``.
    public internal(set) var animation: Animation? = .default

    /// Whether the initial columns have been resolved.
    public internal(set) var isSetup: Bool = false
    private var initialSidebar: Coordinator.Destinations?
    private var initialContent: Coordinator.Destinations?
    private var initialDetail: Coordinator.Destinations?
    private weak var coordinator: Coordinator?

    /// Creates a two-column split.
    ///
    /// - Parameters:
    ///   - sidebar: The sidebar destination.
    ///   - detail: The detail shown before any selection, usually a placeholder.
    ///   - visibility: The initial column visibility.
    ///   - preferredCompactColumn: The column shown at compact width.
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

    /// Creates a three-column split.
    ///
    /// - Parameters:
    ///   - sidebar: The sidebar destination.
    ///   - content: The middle-column destination.
    ///   - detail: The detail shown before any selection, usually a placeholder.
    ///   - visibility: The initial column visibility.
    ///   - preferredCompactColumn: The column shown at compact width.
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

    /// Resolves the initial columns once; later calls do nothing.
    ///
    /// The framework calls this before rendering or navigating.
    ///
    /// - Parameter coordinator: The coordinator that owns this container.
    public func setup(for coordinator: Coordinator) {
        guard !isSetup else { return }
        isSetup = true
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

    }

    /// Records the coordinator hosting this split. The framework calls it.
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
        dest.coordinatable?.attach(to: coordinator, navigationLayer: false, presentation: presentedAs)

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
        if let coordinator {
            dest.coordinatable?.attach(to: coordinator, navigationLayer: false, presentation: presentedAs)
        }
        if let presentedAs, dest.pushType == nil {
            dest.setPushType(presentedAs)
            propagateDestinationType(to: dest.coordinatable, as: presentedAs)
        }

        let previous = self.destination(for: column)
        withScaffoldingAnimation(animation) {
            switch column {
            case .sidebar: sidebar = dest
            case .content: content = dest
            case .detail: detail = dest
            }
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
        let previous = content
        withScaffoldingAnimation(animation) {
            initialContent = nil
            content = nil
        }
        previous?.resolveDismissal()
    }
}

@MainActor
protocol _MutableSplitColumns: AnySplitColumns, _MutableCoordinatableData {
    var animation: Animation? { get set }
    var sidebar: Destination? { get set }
    var content: Destination? { get set }
    var detail: Destination? { get set }
    var columnVisibility: NavigationSplitViewVisibility { get set }
    var preferredCompactColumn: NavigationSplitViewColumn { get set }
    var presentedAs: PresentationType? { get set }
    var modals: [Destination] { get set }
}

extension SplitColumns: _MutableSplitColumns {}
