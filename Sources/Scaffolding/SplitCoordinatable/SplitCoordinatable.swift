//
//  SplitCoordinatable.swift
//  Scaffolding
//
//  Created by Alexandr Valíček on 21.08.2026.
//

import SwiftUI
import Observation
import os.log

/// A coordinator that manages a `NavigationSplitView` interface —
/// sidebar, optional content column, and detail.
///
/// Conform to `SplitCoordinatable` to build master–detail interfaces
/// (iPad, Mac) where each column is a destination — either a plain view
/// or a child coordinator. Provide a ``SplitColumns`` property and define
/// destination functions using the ``Scaffoldable(injectsCoordinator:codable:)``
/// macro. Column assignment happens in the ``SplitColumns`` initializer;
/// the route functions keep the ordinary auto-tracked return types.
///
/// ```swift
/// @Scaffoldable @Observable
/// final class LibraryCoordinator: @MainActor SplitCoordinatable {
///     var columns = SplitColumns<LibraryCoordinator>(
///         sidebar: .sidebar,
///         detail: .placeholder
///     )
///
///     private(set) var selectedPlanetId: Int?
///
///     func sidebar() -> some View { SidebarList() }
///     func placeholder() -> some View { ContentUnavailableView.search }
///     func planet(id: Int) -> any Coordinatable { PlanetFlowCoordinator(id: id) }
///
///     // Guard re-selection on domain state: every planet is the same
///     // `.planet` case, and `RoutePolicy.distinct` compares case
///     // identity only, so it cannot tell two planets apart.
///     func select(_ planet: Planet) {
///         guard selectedPlanetId != planet.id else { return }
///         selectedPlanetId = planet.id
///         setDetail(.planet(id: planet.id))
///     }
/// }
/// ```
///
/// A child ``FlowCoordinatable`` placed in a column builds its own
/// `NavigationStack` there — exactly the composition SwiftUI expects
/// inside a `NavigationSplitView` column — so pushes, pops, and modals
/// inside a column work with the ordinary flow APIs.
///
/// A `SplitCoordinatable` must never live inside a ``FlowCoordinatable``
/// (SwiftUI does not support `NavigationSplitView` inside a
/// `NavigationStack`). Host it on a ``RootCoordinatable``, as a
/// ``TabCoordinatable`` tab, or present it modally.
@MainActor
public protocol SplitCoordinatable: Coordinatable where ViewType == SplitCoordinatableView {
    /// The observable container that holds this coordinator's column
    /// destinations.
    var columns: SplitColumns<Self> { get }

    /// A type-erased accessor for the column container.
    var anySplitColumns: any AnySplitColumns { get }
}

@MainActor
public extension SplitCoordinatable {
    var _dataId: ObjectIdentifier {
        columns.id
    }

    var anySplitColumns: any AnySplitColumns {
        columns.setup(for: self)
        return columns
    }

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
        columns.hasLayerNavigationCoordinator = value
    }

    func setParent(_ parent: any Coordinatable) {
        columns.setParent(parent)
    }
}

// MARK: - Column visibility

@MainActor
public extension SplitCoordinatable {
    /// The current visibility of the split view's leading columns.
    ///
    /// Reflects interactive changes too — the sidebar toggle and edge
    /// swipes write back into this value.
    var columnVisibility: NavigationSplitViewVisibility {
        anySplitColumns.columnVisibility
    }

    /// Sets the visibility of the split view's leading columns.
    ///
    /// - Parameter value: The desired visibility (`.automatic`, `.all`,
    ///   `.doubleColumn`, or `.detailOnly`).
    /// - Returns: `self` for chaining.
    @discardableResult
    func setColumnVisibility(_ value: NavigationSplitViewVisibility) -> Self {
        anySplitColumns.columnVisibility = value
        return self
    }

    /// Sets the column shown when the split view collapses to a single
    /// column (compact width).
    ///
    /// - Parameter value: The preferred compact column.
    /// - Returns: `self` for chaining.
    @discardableResult
    func setPreferredCompactColumn(_ value: NavigationSplitViewColumn) -> Self {
        anySplitColumns.preferredCompactColumn = value
        return self
    }

    /// Whether the current ``columnVisibility`` shows the sidebar column.
    ///
    /// `false` for `.detailOnly`, and for `.doubleColumn` on a
    /// three-column split (where the two visible columns are content and
    /// detail). Reflects the *requested* visibility — `.automatic` can
    /// still hide the sidebar at narrow widths.
    var isSidebarVisible: Bool {
        let visibility = anySplitColumns.columnVisibility
        if visibility == .detailOnly { return false }
        if anySplitColumns.hasContentColumn && visibility == .doubleColumn { return false }
        return true
    }

    /// Toggles the sidebar, macOS-style: hides it with `.detailOnly` when
    /// ``isSidebarVisible``, restores `.all` otherwise. Animated.
    ///
    /// SwiftUI's own sidebar button (and `SidebarCommands()` on macOS)
    /// already does this — reach for `toggleSidebar()` from your own
    /// chrome: a toolbar button, a menu command, or a keyboard shortcut.
    ///
    /// - Returns: `self` for chaining.
    @discardableResult
    func toggleSidebar() -> Self {
        withAnimation {
            anySplitColumns.columnVisibility = isSidebarVisible ? .detailOnly : .all
        }
        return self
    }
}

// MARK: - Column navigation

@MainActor
public extension SplitCoordinatable {
    /// Replaces the destination shown in the detail column.
    ///
    /// The previous detail destination is torn down — its `onDismiss`
    /// (and any awaiting continuation) fires exactly once, and a child
    /// coordinator loses its pushed state. Pass ``RoutePolicy/distinct``
    /// so re-selecting the destination **case** that is already showing
    /// keeps the current detail (and its navigation state) instead of
    /// rebuilding it.
    ///
    /// `.distinct` compares case identity only — associated values are
    /// ignored, so it cannot distinguish `.planet(id: 1)` from
    /// `.planet(id: 2)`. When one parameterized case backs many
    /// selections, guard on your own domain state instead (see the
    /// ``SplitCoordinatable`` overview).
    ///
    /// - Parameters:
    ///   - destination: The destination to show in the detail column.
    ///   - policy: Pass ``RoutePolicy/distinct`` to skip the replacement
    ///     when the same destination case is already showing. Defaults to
    ///     ``RoutePolicy/always``.
    /// - Returns: `self` for chaining.
    @discardableResult
    func setDetail(_ destination: Destinations, policy: RoutePolicy = .always) -> Self {
        guard !columnPolicySkips(destination, column: .detail, policy: policy) else { return self }
        _ = performSetColumn(.detail, to: destination)
        return self
    }

    /// Replaces the destination shown in the middle content column,
    /// installing the column when the split view doesn't have one — the
    /// container swaps from `NavigationSplitView`'s two-column form to
    /// its three-column form.
    ///
    /// - Parameters:
    ///   - destination: The destination to show in the content column.
    ///   - policy: See ``setDetail(_:policy:)``.
    /// - Returns: `self` for chaining.
    @discardableResult
    func setContent(_ destination: Destinations, policy: RoutePolicy = .always) -> Self {
        guard !columnPolicySkips(destination, column: .content, policy: policy) else { return self }
        _ = performSetColumn(.content, to: destination)
        return self
    }

    /// Drops the content column, returning to the two-column form.
    ///
    /// The removed destination's `onDismiss` (and any awaiting
    /// continuation) fires exactly once; a child coordinator loses its
    /// state. Does nothing when no content column is present.
    ///
    /// - Returns: `self` for chaining.
    @discardableResult
    func removeContent() -> Self {
        _ = anySplitColumns // resolve initial columns first
        columns.removeContent()
        return self
    }

    /// Replaces the destination shown in the sidebar column.
    ///
    /// The sidebar is usually structural and set once in the
    /// ``SplitColumns`` initializer — reach for this only when the
    /// sidebar itself genuinely changes (e.g. switching data sets).
    ///
    /// - Parameters:
    ///   - destination: The destination to show in the sidebar column.
    ///   - policy: See ``setDetail(_:policy:)``.
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
    /// Replaces the detail column and invokes a typed callback with the
    /// resolved child coordinator — the split-view leg of a deep-link
    /// chain:
    ///
    /// ```swift
    /// split.setDetail(.planet(id: 4)) { (flow: PlanetFlowCoordinator) in
    ///     flow.route(to: .moon(id: 2))
    /// }
    /// ```
    @discardableResult
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

    /// Replaces the content column and invokes a typed callback with the
    /// resolved child coordinator. See ``setDetail(_:policy:_:)``.
    @discardableResult
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

    /// Replaces the sidebar column and invokes a typed callback with the
    /// resolved child coordinator. See ``setDetail(_:policy:_:)``.
    @discardableResult
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
    /// Replaces the detail column and returns its resolved child
    /// coordinator.
    ///
    /// A non-closure alternative to ``setDetail(_:policy:_:)`` that
    /// flattens deep-link chains — see
    /// ``RootCoordinatable/setRoot(_:animation:expecting:)``.
    ///
    /// - Returns: The child coordinator cast to `T`, or `nil` when the
    ///   destination is view-only, resolves to a different type, or the
    ///   policy skipped the replacement.
    func setDetail<T: Coordinatable>(
        _ destination: Destinations,
        policy: RoutePolicy = .always,
        expecting coordinatorType: T.Type
    ) -> T? {
        guard !columnPolicySkips(destination, column: .detail, policy: policy) else { return nil }
        return performSetColumn(.detail, to: destination)?.coordinatable as? T
    }

    /// Replaces the content column and returns its resolved child
    /// coordinator. See ``setDetail(_:policy:expecting:)``.
    func setContent<T: Coordinatable>(
        _ destination: Destinations,
        policy: RoutePolicy = .always,
        expecting coordinatorType: T.Type
    ) -> T? {
        guard !columnPolicySkips(destination, column: .content, policy: policy) else { return nil }
        return performSetColumn(.content, to: destination)?.coordinatable as? T
    }

    /// Replaces the sidebar column and returns its resolved child
    /// coordinator. See ``setDetail(_:policy:expecting:)``.
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
    /// The destination case currently shown in the sidebar column.
    var sidebarDestination: Destinations.Meta? {
        anySplitColumns.sidebar?.meta as? Destinations.Meta
    }

    /// The destination case currently shown in the content column, or
    /// `nil` for a two-column split view.
    var contentDestination: Destinations.Meta? {
        anySplitColumns.content?.meta as? Destinations.Meta
    }

    /// The destination case currently shown in the detail column.
    var detailDestination: Destinations.Meta? {
        anySplitColumns.detail?.meta as? Destinations.Meta
    }

    /// Returns whether the given destination is currently shown in the
    /// detail column.
    func isDetail(_ destination: Destinations.Meta) -> Bool {
        detailDestination == destination
    }
}

@MainActor
extension SplitCoordinatable {
    @discardableResult
    func performSetColumn(_ column: SplitColumn, to destination: Destinations) -> Destination? {
        _ = anySplitColumns // resolve initial columns so cold-launch deep links land
        let dest = destination.resolvedValue(for: self)
        return columns.replace(column, with: dest)
    }

    /// Whether a `.distinct` policy should skip this column replacement.
    func columnPolicySkips(
        _ destination: Destinations,
        column: SplitColumn,
        policy: RoutePolicy
    ) -> Bool {
        guard case .distinct = policy else { return false }
        _ = anySplitColumns // resolve initial columns before comparing
        guard let currentMeta = columns.destination(for: column)?.meta as? Destinations.Meta else {
            return false
        }
        return currentMeta == destination.meta
    }
}

// MARK: - Modal presentation

@MainActor
public extension SplitCoordinatable {
    /// Presents a destination modally on this split coordinator.
    ///
    /// The modal lives on this coordinator's container and is rendered
    /// as a sheet or full-screen cover above the `NavigationSplitView`.
    ///
    /// The `onDismiss` closure has `async` alternatives: `await`
    /// ``SplitCoordinatable/presentAndWait(_:as:policy:)`` to continue once the modal closes, or
    /// ``SplitCoordinatable/present(_:as:policy:awaiting:)`` to take a value back from it.
    ///
    /// - Parameters:
    ///   - destination: The destination to present.
    ///   - type: The modal presentation style. Defaults to `.sheet`.
    ///   - policy: Pass ``RoutePolicy/distinct`` to skip the presentation
    ///     when the same destination case is already presented. Defaults
    ///     to ``RoutePolicy/always``.
    ///   - onDismiss: A closure invoked when the modal is dismissed.
    /// - Returns: `self` for chaining.
    @discardableResult
    func present(
        _ destination: Destinations,
        as type: ModalPresentationType = .sheet,
        policy: RoutePolicy = .always,
        onDismiss: @escaping @MainActor () -> Void = { }
    ) -> Self {
        guard !modalPolicySkips(destination, policy: policy) else { return self }
        _ = performPresent(destination, as: type, onDismiss: onDismiss)
        return self
    }

    /// Presents a destination modally and invokes a typed callback with the
    /// resolved child coordinator.
    ///
    /// The callback fires once after the modal lands above the split view,
    /// receiving the newly created coordinator cast to `T`. If the
    /// destination does not resolve to a coordinator of type `T`, the
    /// callback is not invoked.
    @discardableResult
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

    /// Presents a destination modally and returns its resolved child
    /// coordinator, if any.
    func present<T: Coordinatable>(
        _ destination: Destinations,
        as type: ModalPresentationType = .sheet,
        policy: RoutePolicy = .always,
        onDismiss: @escaping @MainActor () -> Void = { },
        expecting coordinatorType: T.Type
    ) -> T? {
        guard !modalPolicySkips(destination, policy: policy) else { return nil }
        return performPresent(destination, as: type, onDismiss: onDismiss).coordinatable as? T
    }

    /// Whether this coordinator currently presents a modal (sheet or
    /// full-screen cover) above the `NavigationSplitView`.
    var isPresentingModal: Bool {
        !anySplitColumns.modals.isEmpty
    }
}

// MARK: - Awaitable presentation

@MainActor
public extension SplitCoordinatable {
    /// Presents a destination modally and suspends until it is dismissed.
    ///
    /// See ``FlowCoordinatable/presentAndWait(_:as:policy:)`` — identical
    /// semantics, hosted above the `NavigationSplitView`.
    func presentAndWait(
        _ destination: Destinations,
        as type: ModalPresentationType = .sheet,
        policy: RoutePolicy = .always
    ) async {
        guard !modalPolicySkips(destination, policy: policy) else { return }
        let dest = performPresent(destination, as: type, onDismiss: { })
        await dest.resolution.awaitResolution()
    }

    /// Presents a destination modally and suspends until it is dismissed,
    /// returning the value the presented coordinator handed back via
    /// ``Coordinatable/dismissCoordinator(returning:)``.
    ///
    /// See ``FlowCoordinatable/present(_:as:policy:awaiting:)`` —
    /// identical semantics, hosted above the `NavigationSplitView`.
    func present<Result>(
        _ destination: Destinations,
        as type: ModalPresentationType = .sheet,
        policy: RoutePolicy = .always,
        awaiting resultType: Result.Type
    ) async -> Result? {
        guard !modalPolicySkips(destination, policy: policy) else { return nil }
        let dest = performPresent(destination, as: type, onDismiss: { })
        await dest.resolution.awaitResolution()
        return dest.resolution.result as? Result
    }
}

@MainActor
extension SplitCoordinatable {
    func modalPolicySkips(_ destination: Destinations, policy: RoutePolicy) -> Bool {
        guard case .distinct = policy else { return false }
        return anySplitColumns.modals.contains { dest in
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
        dest.coordinatable?.setHasLayerNavigationCoordinatable(false)
        dest.coordinatable?.setParent(self)

        if let flowCoordinator = dest.coordinatable as? any FlowCoordinatable {
            flowCoordinator.setPresentedAs(type.presentationType)
        } else if let tabCoordinator = dest.coordinatable as? any TabCoordinatable {
            tabCoordinator.setPresentedAs(type.presentationType)
        } else if let rootCoordinator = dest.coordinatable as? any RootCoordinatable {
            rootCoordinator.setPresentedAs(type.presentationType)
        } else if let splitCoordinator = dest.coordinatable as? any SplitCoordinatable {
            splitCoordinator.setPresentedAs(type.presentationType)
        }

        anySplitColumns.modals.append(dest)
        return dest
    }
}

public extension SplitCoordinatable {
    func setPresentedAs(_ type: PresentationType) {
        anySplitColumns.presentedAs = type
        if var sidebar = anySplitColumns.sidebar, sidebar.pushType == nil {
            sidebar.setPushType(type)
            anySplitColumns.sidebar = sidebar
        }
        if var content = anySplitColumns.content, content.pushType == nil {
            content.setPushType(type)
            anySplitColumns.content = content
        }
        if var detail = anySplitColumns.detail, detail.pushType == nil {
            detail.setPushType(type)
            anySplitColumns.detail = detail
        }
    }
}

// MARK: - Bindings

@MainActor
extension SplitCoordinatable {
    var columnVisibilityBinding: Binding<NavigationSplitViewVisibility> {
        Binding(
            get: { self.anySplitColumns.columnVisibility },
            set: { self.anySplitColumns.columnVisibility = $0 }
        )
    }

    var preferredCompactColumnBinding: Binding<NavigationSplitViewColumn> {
        Binding(
            get: { self.anySplitColumns.preferredCompactColumn },
            set: { self.anySplitColumns.preferredCompactColumn = $0 }
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

/// The SwiftUI view generated by a ``SplitCoordinatable`` coordinator.
///
/// You never create this view directly — access ``Coordinatable/view``
/// on a `SplitCoordinatable` coordinator to obtain it.
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
        if _coordinator.anySplitColumns.hasContentColumn {
            NavigationSplitView(
                columnVisibility: _coordinator.columnVisibilityBinding,
                preferredCompactColumn: _coordinator.preferredCompactColumnBinding
            ) {
                column(_coordinator.anySplitColumns.sidebar)
            } content: {
                column(_coordinator.anySplitColumns.content)
            } detail: {
                column(_coordinator.anySplitColumns.detail)
            }
        } else {
            NavigationSplitView(
                columnVisibility: _coordinator.columnVisibilityBinding,
                preferredCompactColumn: _coordinator.preferredCompactColumnBinding
            ) {
                column(_coordinator.anySplitColumns.sidebar)
            } detail: {
                column(_coordinator.anySplitColumns.detail)
            }
        }
    }

    private func modals(of type: ModalPresentationType) -> [Destination] {
        let target = type.presentationType
        return _coordinator.anySplitColumns.modals.filter { $0.pushType == target }
    }

    public var body: some View {
        _coordinator.customize(
            AnyView(
                splitView()
            )
        )
        .applyContainerModals(
            sheets: modals(of: .sheet),
            fullScreenCovers: modals(of: .fullScreenCover),
            onDismissSheet: { id in (_coordinator as any Coordinatable).removeContainerModal(id: id, type: .sheet) },
            onDismissFullScreenCover: { id in (_coordinator as any Coordinatable).removeContainerModal(id: id, type: .fullScreenCover) },
            modalContent: wrappedView
        )
        .environmentCoordinatable(coordinator)
        .id(_coordinator.anySplitColumns.id)
    }
}
