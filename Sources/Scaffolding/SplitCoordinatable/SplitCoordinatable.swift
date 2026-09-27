//
//  SplitCoordinatable.swift
//  Scaffolding
//
//  Created by Alexandr Valíček on 21.08.2026.
//

import SwiftUI
import Observation
import os.log

/// A coordinator that renders a `NavigationSplitView` with a sidebar, an
/// optional content column, and a detail column.
///
/// Each column shows one destination: a view or a child coordinator. Assign
/// the initial columns in ``SplitColumns``; routes keep their ordinary return
/// types. A child ``FlowCoordinatable`` in a column gets its own stack.
///
/// ```swift
/// @MainActor @Observable @Scaffoldable
/// final class LibraryCoordinator: @MainActor SplitCoordinatable {
///     var columns = SplitColumns<LibraryCoordinator>(
///         sidebar: .sidebar,
///         detail: .placeholder
///     )
///
///     private(set) var selectedPlanetID: Int?
///
///     func sidebar() -> some View { SidebarList() }
///     func placeholder() -> some View { ContentUnavailableView.search }
///     func planet(id: Int) -> any Coordinatable { PlanetFlowCoordinator(id: id) }
/// }
///
/// extension LibraryCoordinator {
///     func select(_ planet: Planet) {
///         guard selectedPlanetID != planet.id else { return }
///         selectedPlanetID = planet.id
///         setDetail(.planet(id: planet.id))
///     }
/// }
/// ```
///
/// Column setters replace the column; they don't push. Guard re-selection
/// on domain identity, because ``RoutePolicy/distinct`` compares cases only.
///
/// Host a split as a root destination, a tab, or a modal. Never push it or
/// use it as a flow's root. See <doc:SplitViews>.
///
/// ## Topics
///
/// ### Replacing Columns
///
/// - ``setSidebar(_:policy:)``
/// - ``setSidebar(_:policy:expecting:)``
/// - ``setContent(_:policy:)``
/// - ``setContent(_:policy:expecting:)``
/// - ``setDetail(_:policy:)``
/// - ``setDetail(_:policy:expecting:)``
/// - ``removeContent()``
///
/// ### Reading Column State
///
/// - ``columns``
/// - ``sidebarDestination``
/// - ``contentDestination``
/// - ``detailDestination``
/// - ``isDetail(_:)``
///
/// ### Adapting the Layout
///
/// - ``setColumnVisibility(_:)``
/// - ``columnVisibility``
/// - ``toggleSidebar()``
/// - ``isSidebarVisible``
/// - ``setPreferredCompactColumn(_:)``
///
/// ### Presenting and Receiving Results
///
/// - ``Coordinatable/present(_:as:policy:)``
/// - ``Coordinatable/present(_:as:policy:expecting:)``
/// - ``Coordinatable/present(_:as:policy:awaiting:)``
/// - ``Coordinatable/present(_:as:policy:expecting:awaiting:)``
///
/// ### Closing Flows and Modals
///
/// - ``Coordinatable/dismissCoordinator()``
/// - ``Coordinatable/dismissCoordinator(returning:)``
/// - ``Coordinatable/dismissPresentedModal()``
/// - ``Coordinatable/cancelPendingModals()``
/// - ``Coordinatable/dismissModal()``
/// - ``Coordinatable/dismissAllModals()``
/// - ``Coordinatable/isPresentingModal``
/// - ``Coordinatable/pendingModalCount``
///
/// ### Transition Animation
///
/// - ``setTransitionAnimation(_:)``
///
/// ### Type-Erased State
///
/// - ``anySplitColumns``
///
/// ### Presentation Context
///
/// - ``setPresentedAs(_:)``
///
/// ### Deprecated Compatibility
///
/// - ``present(_:as:policy:onDismiss:)``
/// - ``present(_:as:policy:onDismiss:_:)``
/// - ``present(_:as:policy:onDismiss:expecting:)``
/// - ``presentAndWait(_:as:policy:)``
/// - ``setContent(_:policy:_:)``
/// - ``setDetail(_:policy:_:)``
/// - ``setSidebar(_:policy:_:)``
@MainActor
public protocol SplitCoordinatable: Coordinatable where ViewType == SplitCoordinatableView {
    /// The container holding this coordinator's columns, layout, and modal
    /// requests.
    ///
    /// Seed it in the initializer and change it through the coordinator's
    /// methods. Never replace a live container.
    var columns: SplitColumns<Self> { get }

    /// Type-erased, read-only access to ``columns``.
    var anySplitColumns: any AnySplitColumns { get }

    /// Framework access that does not resolve initial destinations.
    var _uninitializedSplitColumns: any AnySplitColumns { get }
}

@MainActor
public extension SplitCoordinatable {
    var _dataId: ObjectIdentifier {
        columns.id
    }

    var _uninitializedSplitColumns: any AnySplitColumns { columns }

    var anySplitColumns: any AnySplitColumns {
        columns.setup(for: self)
        return columns
    }

    /// The rendered split coordinator and everything below it.
    ///
    /// Show the top-level coordinator's `view` once, usually in a `WindowGroup`.
    /// Child coordinators render through their parent.
    var view: SplitCoordinatableView {
        columns.setup(for: self)
        return .init(coordinator: self)
    }

    var parent: (any Coordinatable)? {
        columns.parent
    }

    var hasLayerNavigationCoordinatable: Bool {
        columns.hasLayerNavigationCoordinator
    }

    func setHasLayerNavigationCoordinatable(_ value: Bool) {
        updateNavigationContext(navigationLayer: value, presentation: inheritedPresentation)
    }

    func setParent(_ parent: any Coordinatable) {
        columns.setParent(parent)
    }
}

// MARK: - Column visibility

@MainActor
public extension SplitCoordinatable {
    /// The current column visibility.
    ///
    /// User changes, such as the sidebar button or an edge swipe, write back
    /// to this value.
    var columnVisibility: NavigationSplitViewVisibility {
        _resolvedSplitColumns.columnVisibility
    }

    /// Sets which columns are visible, using the default animation.
    ///
    /// - Parameter value: `.automatic`, `.all`, `.doubleColumn`, or `.detailOnly`.
    /// - Returns: `self` for chaining.
    @discardableResult
    func setColumnVisibility(_ value: NavigationSplitViewVisibility) -> Self {
        withNavigationAnimation { _resolvedSplitColumns.columnVisibility = value }
        return self
    }

    /// Sets the column shown when the split collapses to one column at
    /// compact width.
    ///
    /// Use it when a deep link should land on the detail.
    ///
    /// - Parameter value: The column to show.
    /// - Returns: `self` for chaining.
    @discardableResult
    func setPreferredCompactColumn(_ value: NavigationSplitViewColumn) -> Self {
        withNavigationAnimation { _resolvedSplitColumns.preferredCompactColumn = value }
        return self
    }

    /// Whether the requested ``columnVisibility`` includes the sidebar.
    ///
    /// `false` for `.detailOnly`, and for `.doubleColumn` in a three-column
    /// split. `.automatic` reads `true` even when the system hides the
    /// sidebar at narrow widths.
    var isSidebarVisible: Bool {
        let visibility = _resolvedSplitColumns.columnVisibility
        if visibility == .detailOnly { return false }
        if _resolvedSplitColumns.hasContentColumn && visibility == .doubleColumn { return false }
        return true
    }

    /// Hides the sidebar with `.detailOnly` when ``isSidebarVisible``;
    /// otherwise shows every column with `.all`.
    ///
    /// Call it from your own toolbar button, menu command, or shortcut.
    /// SwiftUI's sidebar button and `SidebarCommands()` already toggle it.
    ///
    /// - Returns: `self` for chaining.
    @discardableResult
    func toggleSidebar() -> Self {
        withNavigationAnimation {
            _resolvedSplitColumns.columnVisibility = isSidebarVisible ? .detailOnly : .all
        }
        return self
    }
}

// MARK: - Column navigation

@MainActor
public extension SplitCoordinatable {
    /// Replaces the detail column with a new destination.
    ///
    /// The previous detail branch is removed: its waiting callers resume
    /// with `nil`, and a child coordinator loses its navigation state.
    /// `.distinct` compares cases only, so `.planet(id: 1)` matches
    /// `.planet(id: 2)`; guard record identity yourself.
    ///
    /// - Parameters:
    ///   - destination: The destination to show.
    ///   - policy: `.distinct` skips the change when the column already
    ///     shows this case. Defaults to `.always`.
    /// - Returns: `self` for chaining.
    @discardableResult
    func setDetail(_ destination: Destinations, policy: RoutePolicy = .always) -> Self {
        guard !columnPolicySkips(destination, column: .detail, policy: policy) else { return self }
        _ = performSetColumn(.detail, to: destination)
        return self
    }

    /// Replaces the content column, adding it when the split has only two
    /// columns.
    ///
    /// The previous content branch is removed as in ``setDetail(_:policy:)``.
    ///
    /// - Parameters:
    ///   - destination: The destination to show.
    ///   - policy: `.distinct` skips the change when the column already
    ///     shows this case. Defaults to `.always`.
    /// - Returns: `self` for chaining.
    @discardableResult
    func setContent(_ destination: Destinations, policy: RoutePolicy = .always) -> Self {
        guard !columnPolicySkips(destination, column: .content, policy: policy) else { return self }
        _ = performSetColumn(.content, to: destination)
        return self
    }

    /// Removes the content column, returning to two columns.
    ///
    /// Its waiting callers resume with `nil`, and a child coordinator loses
    /// its navigation state. Does nothing without a content column.
    ///
    /// - Returns: `self` for chaining.
    @discardableResult
    func removeContent() -> Self {
        _ = _resolvedSplitColumns // resolve initial columns first
        columns.removeContent()
        return self
    }

    /// Replaces the sidebar column.
    ///
    /// Set the sidebar in ``SplitColumns`` and replace it only when the
    /// sidebar itself changes. The previous branch is removed as in
    /// ``setDetail(_:policy:)``.
    ///
    /// - Parameters:
    ///   - destination: The destination to show.
    ///   - policy: `.distinct` skips the change when the column already
    ///     shows this case. Defaults to `.always`.
    /// - Returns: `self` for chaining.
    @discardableResult
    func setSidebar(_ destination: Destinations, policy: RoutePolicy = .always) -> Self {
        guard !columnPolicySkips(destination, column: .sidebar, policy: policy) else { return self }
        _ = performSetColumn(.sidebar, to: destination)
        return self
    }
}

// MARK: - Column navigation, typed callbacks

@MainActor
public extension SplitCoordinatable {
    /// Deprecated. Use ``setDetail(_:policy:expecting:)`` instead.
    ///
    /// Continue through the returned child instead of a callback.
    @discardableResult
    @available(*, deprecated, message: "Will be removed in a future update. Use the expecting: overload to access the child coordinator.")
    func setDetail<T: Coordinatable>(
        _ destination: Destinations,
        policy: RoutePolicy = .always,
        _ action: @escaping @MainActor (T) -> Void
    ) -> Self {
        guard !columnPolicySkips(destination, column: .detail, policy: policy) else { return self }
        if let coordinator = performSetColumn(.detail, to: destination)?.coordinatable as? T {
            action(coordinator)
        }
        return self
    }

    /// Deprecated. Use ``setContent(_:policy:expecting:)`` instead.
    ///
    /// Continue through the returned child instead of a callback.
    @discardableResult
    @available(*, deprecated, message: "Will be removed in a future update. Use the expecting: overload to access the child coordinator.")
    func setContent<T: Coordinatable>(
        _ destination: Destinations,
        policy: RoutePolicy = .always,
        _ action: @escaping @MainActor (T) -> Void
    ) -> Self {
        guard !columnPolicySkips(destination, column: .content, policy: policy) else { return self }
        if let coordinator = performSetColumn(.content, to: destination)?.coordinatable as? T {
            action(coordinator)
        }
        return self
    }

    /// Deprecated. Use ``setSidebar(_:policy:expecting:)`` instead.
    ///
    /// Continue through the returned child instead of a callback.
    @discardableResult
    @available(*, deprecated, message: "Will be removed in a future update. Use the expecting: overload to access the child coordinator.")
    func setSidebar<T: Coordinatable>(
        _ destination: Destinations,
        policy: RoutePolicy = .always,
        _ action: @escaping @MainActor (T) -> Void
    ) -> Self {
        guard !columnPolicySkips(destination, column: .sidebar, policy: policy) else { return self }
        if let coordinator = performSetColumn(.sidebar, to: destination)?.coordinatable as? T {
            action(coordinator)
        }
        return self
    }
}

// MARK: - Column navigation, typed child resolution

@MainActor
public extension SplitCoordinatable {
    /// Replaces the detail column and returns the child as `T`, or `nil` for
    /// a view route or another type. The navigation happens either way.
    ///
    /// A `.distinct` skip returns `nil` without navigating. Use the child to
    /// continue a deep link; see <doc:DeepLinking>.
    ///
    /// - Parameters:
    ///   - destination: The destination to show.
    ///   - policy: `.distinct` skips the change when the column already
    ///     shows this case. Defaults to `.always`.
    ///   - coordinatorType: The child type the route builds.
    /// - Returns: The child, or `nil`.
    func setDetail<T: Coordinatable>(
        _ destination: Destinations,
        policy: RoutePolicy = .always,
        expecting coordinatorType: T.Type
    ) -> T? {
        guard !columnPolicySkips(destination, column: .detail, policy: policy) else { return nil }
        return performSetColumn(.detail, to: destination)?.coordinatable as? T
    }

    /// Replaces the content column and returns the child as `T`, or `nil`
    /// for a view route or another type. The navigation happens either way.
    ///
    /// Adds the column when the split has only two. A `.distinct` skip
    /// returns `nil` without navigating.
    func setContent<T: Coordinatable>(
        _ destination: Destinations,
        policy: RoutePolicy = .always,
        expecting coordinatorType: T.Type
    ) -> T? {
        guard !columnPolicySkips(destination, column: .content, policy: policy) else { return nil }
        return performSetColumn(.content, to: destination)?.coordinatable as? T
    }

    /// Replaces the sidebar column and returns the child as `T`, or `nil`
    /// for a view route or another type. The navigation happens either way.
    ///
    /// A `.distinct` skip returns `nil` without navigating.
    func setSidebar<T: Coordinatable>(
        _ destination: Destinations,
        policy: RoutePolicy = .always,
        expecting coordinatorType: T.Type
    ) -> T? {
        guard !columnPolicySkips(destination, column: .sidebar, policy: policy) else { return nil }
        return performSetColumn(.sidebar, to: destination)?.coordinatable as? T
    }
}

// MARK: - Introspection

@MainActor
public extension SplitCoordinatable {
    /// The route case in the sidebar column.
    var sidebarDestination: Destinations.Meta? {
        _resolvedSplitColumns.sidebar?.meta as? Destinations.Meta
    }

    /// The route case in the content column, or `nil` for a two-column split.
    var contentDestination: Destinations.Meta? {
        _resolvedSplitColumns.content?.meta as? Destinations.Meta
    }

    /// The route case in the detail column.
    var detailDestination: Destinations.Meta? {
        _resolvedSplitColumns.detail?.meta as? Destinations.Meta
    }

    /// Returns whether the detail column shows the given case, ignoring its
    /// payload.
    func isDetail(_ destination: Destinations.Meta) -> Bool {
        detailDestination == destination
    }
}

@MainActor
extension SplitCoordinatable {
    @discardableResult
    func performSetColumn(_ column: SplitColumn, to destination: Destinations) -> Destination? {
        _ = _resolvedSplitColumns // resolve initial columns so cold-launch deep links land
        let dest = destination.resolvedValue(for: self)
        return columns.replace(column, with: dest)
    }

    /// Whether a `.distinct` policy should skip this column replacement.
    func columnPolicySkips(
        _ destination: Destinations,
        column: SplitColumn,
        policy: RoutePolicy
    ) -> Bool {
        guard destination.isAvailable else { return true }
        guard case .distinct = policy else { return false }
        _ = _resolvedSplitColumns // resolve initial columns before comparing
        guard let currentMeta = columns.destination(for: column)?.meta as? Destinations.Meta else {
            return false
        }
        return currentMeta == destination.meta
    }
}

// MARK: - Modal presentation

@MainActor
public extension SplitCoordinatable {
    /// Adds a modal request above the split view.
    ///
    /// The first request shows; later ones wait. Add `awaiting:` to wait for
    /// a result; see <doc:ModalsAndResults>.
    ///
    /// - Parameters:
    ///   - destination: The route to present.
    ///   - type: `.sheet` (the default) or `.fullScreenCover`.
    ///   - policy: `.distinct` skips a case this coordinator already
    ///     requested, including queued requests. Defaults to `.always`.
    /// - Returns: `self` for chaining.
    @discardableResult
    func present(
        _ destination: Destinations,
        as type: ModalPresentationType = .sheet,
        policy: RoutePolicy = .always
    ) -> Self {
        guard !modalPolicySkips(destination, policy: policy) else { return self }
        _ = performPresent(destination, as: type, onDismiss: { })
        return self
    }

    /// Deprecated. Use ``Coordinatable/present(_:as:policy:awaiting:)`` instead.
    ///
    /// Await it with `awaiting: Void.self`, then run the former `onDismiss` code.
    @available(*, deprecated, message: "Will be removed in a future update. Use await present with awaiting: instead; pass Void.self to wait without a result.")
    @discardableResult
    func present(
        _ destination: Destinations,
        as type: ModalPresentationType = .sheet,
        policy: RoutePolicy = .always,
        onDismiss: @escaping @MainActor () -> Void
    ) -> Self {
        guard !modalPolicySkips(destination, policy: policy) else { return self }
        _ = performPresent(destination, as: type, onDismiss: onDismiss)
        return self
    }

    /// Deprecated. Use ``Coordinatable/present(_:as:policy:expecting:)`` instead.
    ///
    /// Add `awaiting:` when dismissal or a result also matters.
    @discardableResult
    @available(*, deprecated, message: "Will be removed in a future update. Use expecting: for child access; combine it with awaiting: for dismissal/results.")
    func present<T: Coordinatable>(
        _ destination: Destinations,
        as type: ModalPresentationType = .sheet,
        policy: RoutePolicy = .always,
        onDismiss: @escaping @MainActor () -> Void = { },
        _ action: @escaping @MainActor (T) -> Void
    ) -> Self {
        guard !modalPolicySkips(destination, policy: policy) else { return self }
        let dest = performPresent(destination, as: type, onDismiss: onDismiss)
        if let coordinator = dest.coordinatable as? T {
            action(coordinator)
        }
        return self
    }

    /// Presents a destination and returns the child as `T`, or `nil` for a
    /// view route or another type. The navigation happens either way.
    ///
    /// A `.distinct` skip returns `nil` without presenting.
    func present<T: Coordinatable>(
        _ destination: Destinations,
        as type: ModalPresentationType = .sheet,
        policy: RoutePolicy = .always,
        expecting coordinatorType: T.Type
    ) -> T? {
        guard !modalPolicySkips(destination, policy: policy) else { return nil }
        return performPresent(destination, as: type, onDismiss: { }).coordinatable as? T
    }

    /// Deprecated. Use ``Coordinatable/present(_:as:policy:expecting:awaiting:)`` instead.
    ///
    /// Await its `result()` where the `onDismiss` code ran.
    @available(*, deprecated, message: "Will be removed in a future update. Use expecting: with awaiting: to get the child immediately and await its result.")
    func present<T: Coordinatable>(
        _ destination: Destinations,
        as type: ModalPresentationType = .sheet,
        policy: RoutePolicy = .always,
        onDismiss: @escaping @MainActor () -> Void,
        expecting coordinatorType: T.Type
    ) -> T? {
        guard !modalPolicySkips(destination, policy: policy) else { return nil }
        return performPresent(destination, as: type, onDismiss: onDismiss).coordinatable as? T
    }

    /// Whether this coordinator has a modal request, including queued requests.
    var isPresentingModal: Bool {
        !_resolvedSplitColumns.modals.isEmpty
    }
}

// MARK: - Awaitable presentation

@MainActor
public extension SplitCoordinatable {
    /// Presents a destination and returns its child and a result waiter
    /// without suspending.
    ///
    /// Configure `coordinator`, then `await result()`. A view route or
    /// another type gives a `nil` coordinator. A `.distinct` skip or an
    /// already-cancelled task presents nothing, and `result()` returns `nil`.
    /// See <doc:ModalsAndResults#Configure-the-child-then-await>.
    func present<T: Coordinatable, Result>(
        _ destination: Destinations,
        as type: ModalPresentationType = .sheet,
        policy: RoutePolicy = .always,
        expecting coordinatorType: T.Type,
        awaiting resultType: Result.Type
    ) -> (coordinator: T?, result: @MainActor () async -> Result?) {
        guard !Task.isCancelled, !modalPolicySkips(destination, policy: policy) else {
            return (nil, { nil })
        }
        let dest = performPresent(destination, as: type, onDismiss: { })
        return (dest.coordinatable as? T, dest.resolution.resultWaiter(for: resultType))
    }

    /// Deprecated. Use ``Coordinatable/present(_:as:policy:awaiting:)`` with
    /// `awaiting: Void.self` instead.
    @available(*, deprecated, message: "Will be removed in a future update. Use await present with awaiting: Void.self to wait for dismissal, or awaiting: Result.self to receive a result.")
    func presentAndWait(
        _ destination: Destinations,
        as type: ModalPresentationType = .sheet,
        policy: RoutePolicy = .always
    ) async {
        guard !Task.isCancelled else { return }
        guard !modalPolicySkips(destination, policy: policy) else { return }
        let dest = performPresent(destination, as: type, onDismiss: { })
        await dest.resolution.awaitResolution()
    }

    /// Presents a destination and suspends until it leaves, returning its
    /// result.
    ///
    /// The child returns a value with ``Coordinatable/dismissCoordinator(returning:)``;
    /// a view uses ``Destination/dismiss(returning:)``. Plain dismissal, a
    /// mismatched type, or a `.distinct` skip returns `nil`. Cancelling the
    /// waiting task returns `nil` and leaves the modal in place.
    func present<Result>(
        _ destination: Destinations,
        as type: ModalPresentationType = .sheet,
        policy: RoutePolicy = .always,
        awaiting resultType: Result.Type
    ) async -> Result? {
        guard !Task.isCancelled else { return nil }
        guard !modalPolicySkips(destination, policy: policy) else { return nil }
        let dest = performPresent(destination, as: type, onDismiss: { })
        await dest.resolution.awaitResolution()
        return Task.isCancelled ? nil : dest.resolution.result as? Result
    }
}

@MainActor
extension SplitCoordinatable {
    func modalPolicySkips(_ destination: Destinations, policy: RoutePolicy) -> Bool {
        guard destination.isAvailable else { return true }
        guard case .distinct = policy else { return false }
        return _resolvedSplitColumns.modals.contains { dest in
            guard let destMeta = dest.meta as? Destinations.Meta else { return false }
            return destMeta == destination.meta
        }
    }

    @discardableResult
    func performPresent(
        _ destination: Destinations,
        as type: ModalPresentationType,
        onDismiss: @escaping @MainActor () -> Void
    ) -> Destination {
        var dest = destination.resolvedValue(for: self)
        dest.setOnDismiss(onDismiss)
        dest.setPushType(type.presentationType)
        dest.setRouteType(DestinationType.from(presentationType: type.presentationType))
        dest.setModalConfiguration(type.configuration)
        dest.coordinatable?.attach(to: self, navigationLayer: false, presentation: type.presentationType)

        withNavigationAnimation { columns.modals.append(dest) }
        return dest
    }
}

public extension SplitCoordinatable {
    /// Records the presentation style this coordinator inherits from a
    /// presented host. The framework calls it; apps don't need to.
    func setPresentedAs(_ type: PresentationType) {
        inheritPresentation(type)
    }
}

// MARK: - Bindings

@MainActor
extension SplitCoordinatable {
    var columnVisibilityBinding: Binding<NavigationSplitViewVisibility> {
        Binding(
            get: { self._resolvedSplitColumns.columnVisibility },
            set: { self._resolvedSplitColumns.columnVisibility = $0 }
        )
    }

    var preferredCompactColumnBinding: Binding<NavigationSplitViewColumn> {
        Binding(
            get: { self._resolvedSplitColumns.preferredCompactColumn },
            set: { self._resolvedSplitColumns.preferredCompactColumn = $0 }
        )
    }
}

// MARK: - Flow-nesting guard

/// Logs a critical error when a destination resolves to a
/// ``SplitCoordinatable`` inside a `NavigationStack`-providing context —
/// SwiftUI does not support `NavigationSplitView` inside a
/// `NavigationStack`.
@MainActor
func _warnIfSplitInsideNavigationStack(_ coordinatable: (any Coordinatable)?) {
    guard coordinatable is any SplitCoordinatable else { return }
    let logger = Logger(subsystem: "Scaffolding", category: "Hierarchy")
    logger.critical("Scaffolding: A SplitCoordinatable cannot live inside a FlowCoordinatable — SwiftUI does not support NavigationSplitView inside a NavigationStack. Host it on a RootCoordinatable, as a TabCoordinatable tab, or present it modally.")
}

/// The view a ``SplitCoordinatable`` renders.
///
/// Get it from ``Coordinatable/view``; don't create it yourself.
public struct SplitCoordinatableView: CoordinatableView {
    private let _coordinator: any SplitCoordinatable

    public var coordinator: any Coordinatable {
        _coordinator
    }

    init(coordinator: any SplitCoordinatable) {
        self._coordinator = coordinator
    }

    @ViewBuilder
    private func column(_ destination: Destination?) -> some View {
        if let destination {
            wrappedView(destination)
                .environmentCoordinatable(_coordinator)
                // Reset the column identity when its destination changes so
                // SwiftUI tears down the previous column content (including
                // a child flow's NavigationStack state) cleanly.
                .id(destination.id)
        } else {
            EmptyView()
        }
    }

    @ViewBuilder
    private func splitView() -> some View {
        if _coordinator._resolvedSplitColumns.hasContentColumn {
            NavigationSplitView(
                columnVisibility: _coordinator.columnVisibilityBinding,
                preferredCompactColumn: _coordinator.preferredCompactColumnBinding
            ) {
                column(_coordinator._resolvedSplitColumns.sidebar)
            } content: {
                column(_coordinator._resolvedSplitColumns.content)
            } detail: {
                column(_coordinator._resolvedSplitColumns.detail)
            }
        } else {
            NavigationSplitView(
                columnVisibility: _coordinator.columnVisibilityBinding,
                preferredCompactColumn: _coordinator.preferredCompactColumnBinding
            ) {
                column(_coordinator._resolvedSplitColumns.sidebar)
            } detail: {
                column(_coordinator._resolvedSplitColumns.detail)
            }
        }
    }

    public var body: some View {
        _coordinator.customize(
            AnyView(
                splitView()
            )
        )
        .applyContainerModals(
            destinations: _coordinator._resolvedSplitColumns.modals,
            onDismissSheet: { id in (_coordinator as any Coordinatable).removeContainerModal(id: id, type: .sheet) },
            onDismissFullScreenCover: { id in (_coordinator as any Coordinatable).removeContainerModal(id: id, type: .fullScreenCover) },
            modalContent: wrappedView
        )
        .environmentCoordinatable(coordinator)
        .id(_coordinator._resolvedSplitColumns.id)
    }
}

@MainActor
extension SplitCoordinatable {
    var _columns: any _MutableSplitColumns { columns }
    var _resolvedSplitColumns: any _MutableSplitColumns {
        columns.setup(for: self)
        return columns
    }
}

@MainActor
public extension SplitCoordinatable {
    /// Sets the default animation for this coordinator's navigation changes.
    /// Pass `nil` to disable it.
    func setTransitionAnimation(_ animation: Animation?) { columns.animation = animation }
}
