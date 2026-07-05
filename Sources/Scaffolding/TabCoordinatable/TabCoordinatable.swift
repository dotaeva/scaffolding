//
//  TabCoordinatable.swift
//  Scaffolding
//
//  Created by Alexandr Valíček on 24.09.2025.
//

import SwiftUI
import Observation

/// A coordinator that manages a tab bar interface.
///
/// Conform to `TabCoordinatable` to build a `TabView` where each tab is
/// a destination — either a plain view or a child coordinator. Provide a
/// ``TabItems`` property and define tab functions using the
/// ``Scaffoldable(injectsCoordinator:)`` macro.
///
/// ```swift
/// @Scaffoldable @Observable
/// final class MainTabCoordinator: @MainActor TabCoordinatable {
///     var tabItems = TabItems<MainTabCoordinator>(
///         tabs: [.home, .settings]
///     )
///
///     func home() -> any Coordinatable { HomeCoordinator() }
///     func settings() -> some View { SettingsView() }
/// }
/// ```
@MainActor
public protocol TabCoordinatable: Coordinatable where ViewType == TabCoordinatableView {
    /// The observable container that holds this coordinator's tab
    /// destinations.
    var tabItems: TabItems<Self> { get }

    /// A type-erased accessor for the tab items.
    var anyTabItems: any AnyTabItems { get }

    /// Decides whether a user-initiated tab selection should be applied.
    ///
    /// The generated `TabView` consults this hook whenever the selection
    /// binding is written through the UI. Return `false` to keep the
    /// current tab — for example to present a login sheet instead of
    /// switching. If the hook performs its own selection (e.g. via
    /// ``selectFirstTab(_:)``), that redirect is preserved.
    ///
    /// When the user re-taps the tab that is already selected, the hook
    /// fires with `isReselection == true` — useful for pop-to-root or
    /// scroll-to-top behavior. The return value is ignored in that case,
    /// since there is no selection change to veto.
    ///
    /// Programmatic selection (``selectFirstTab(_:)``, ``select(index:)``,
    /// and friends) bypasses this hook.
    ///
    /// The default implementation returns `true`.
    func shouldSelect(tab: Destinations.Meta, isReselection: Bool) -> Bool
}

@MainActor
public extension TabCoordinatable {
    func shouldSelect(tab: Destinations.Meta, isReselection: Bool) -> Bool {
        true
    }
}

@MainActor
public extension TabCoordinatable {
    var _dataId: ObjectIdentifier {
        tabItems.id
    }

    var anyTabItems: any AnyTabItems {
        tabItems.setup(for: self)
        return tabItems
    }

    var view: TabCoordinatableView {
        tabItems.setup(for: self)
        return .init(coordinator: self)
    }

    var parent: (any Coordinatable)? {
        tabItems.parent
    }

    var hasLayerNavigationCoordinatable: Bool {
        tabItems.hasLayerNavigationCoordinator
    }

    func setHasLayerNavigationCoordinatable(_ value: Bool) {
        tabItems.hasLayerNavigationCoordinator = value
    }

    func setParent(_ parent: any Coordinatable) {
        tabItems.setParent(parent)
    }

    /// Sets the visibility of the tab bar.
    ///
    /// - Parameter value: The desired visibility (`.automatic`, `.visible`,
    ///   or `.hidden`).
    func setTabBarVisibility(_ value: Visibility) {
        tabItems.setTabBarVisibility(value)
    }
}

@MainActor
extension TabCoordinatable {
    var selectedTabBinding: Binding<UUID?> {
        Binding(
            get: { self.tabItems.selectedTab },
            set: { newValue in
                let current = self.tabItems.selectedTab

                guard newValue != current else {
                    // Re-tap of the already-selected tab: there is no
                    // change to veto, but surface the event to the hook.
                    if let id = newValue,
                       let meta = self.tabItems.tabs.first(where: { $0.id == id })?.meta as? Destinations.Meta {
                        _ = self.shouldSelect(tab: meta, isReselection: true)
                    }
                    return
                }

                if let id = newValue,
                   let meta = self.tabItems.tabs.first(where: { $0.id == id })?.meta as? Destinations.Meta,
                   !self.shouldSelect(tab: meta, isReselection: false) {
                    // Rejected. Unless the hook redirected the selection
                    // itself, re-assert the current tab — the write fires
                    // an observation change so the TabView snaps back.
                    if self.tabItems.selectedTab == current {
                        self.tabItems.selectedTab = current
                    }
                    return
                }

                self.tabItems.selectedTab = newValue
            }
        )
    }
}

@MainActor
public extension TabCoordinatable {
    /// Selects the **first** tab matching the given destination.
    ///
    /// - Parameter tab: The destination meta to select.
    /// - Returns: `self` for chaining.
    @discardableResult
    func selectFirstTab(_ tab: Destinations.Meta) -> Self {
        let _ = tabItems.select(first: tab)
        return self
    }

    /// Selects the **last** tab matching the given destination.
    ///
    /// - Parameter tab: The destination meta to select.
    /// - Returns: `self` for chaining.
    @discardableResult
    func selectLastTab(_ tab: Destinations.Meta) -> Self {
        let _ = tabItems.select(last: tab)
        return self
    }

    /// Selects a tab by its zero-based index.
    ///
    /// - Parameter index: The position of the tab to select.
    /// - Returns: `self` for chaining.
    @discardableResult
    func select(index: Int) -> Self {
        let _ = tabItems.select(index)
        return self
    }

    /// Selects a tab by its unique identifier.
    ///
    /// - Parameter id: The UUID of the tab to select.
    /// - Returns: `self` for chaining.
    @discardableResult
    func select(id: UUID) -> Self {
        let _ = tabItems.select(id)
        return self
    }

    /// Replaces all tabs with the given destinations.
    ///
    /// - Parameter tabs: The new set of tab destinations.
    /// - Returns: `self` for chaining.
    @discardableResult
    func setTabs(_ tabs: [Destinations]) -> Self {
        let tabs = tabs.map {
            let t = $0.resolvedValue(for: self)
            t.coordinatable?.setHasLayerNavigationCoordinatable(self.hasLayerNavigationCoordinatable)
            t.coordinatable?.setParent(self)
            return t
        }

        tabItems.setTabs(tabs)

        return self
    }

    /// Appends a new tab to the end of the tab bar.
    ///
    /// - Parameter tab: The destination to add.
    /// - Returns: `self` for chaining.
    @discardableResult
    func appendTab(_ tab: Destinations) -> Self {
        let tab = tab.resolvedValue(for: self)
        tab.coordinatable?.setHasLayerNavigationCoordinatable(self.hasLayerNavigationCoordinatable)
        tab.coordinatable?.setParent(self)

        let _ = tabItems.appendTab(tab)

        return self
    }

    /// Inserts a new tab at the given index.
    ///
    /// - Parameters:
    ///   - tab: The destination to insert.
    ///   - index: The position at which to insert the tab. The value is
    ///     clamped to the valid range.
    /// - Returns: `self` for chaining.
    @discardableResult
    func insertTab(_ tab: Destinations, at index: Int) -> Self {
        let tab = tab.resolvedValue(for: self)
        tab.coordinatable?.setHasLayerNavigationCoordinatable(self.hasLayerNavigationCoordinatable)
        tab.coordinatable?.setParent(self)

        let _ = tabItems.insertTab(tab, at: index)

        return self
    }

    /// Removes the **first** tab matching the given destination.
    ///
    /// - Parameter meta: The destination meta to remove.
    /// - Returns: `self` for chaining.
    @discardableResult
    func removeFirstTab(_ meta: Destinations.Meta) -> Self {
        tabItems.removeFirstTab(meta)
        return self
    }

    /// Removes the **last** tab matching the given destination.
    ///
    /// - Parameter meta: The destination meta to remove.
    /// - Returns: `self` for chaining.
    @discardableResult
    func removeLastTab(_ meta: Destinations.Meta) -> Self {
        tabItems.removeLastTab(meta)
        return self
    }

    /// Sets or clears the badge on the **first** tab matching the given
    /// destination.
    ///
    /// ```swift
    /// tabCoordinator.setBadge("3", for: .inbox)
    /// tabCoordinator.setBadge(nil, for: .inbox)   // clear
    /// ```
    ///
    /// - Parameters:
    ///   - value: The badge text, or `nil` to remove the badge.
    ///   - tab: The destination meta of the tab to badge.
    /// - Returns: `self` for chaining.
    @discardableResult
    func setBadge(_ value: String?, for tab: Destinations.Meta) -> Self {
        _ = anyTabItems // resolve tabs before the first render if needed
        tabItems.setBadge(value, forFirst: tab)
        return self
    }

    /// Sets a numeric badge on the **first** tab matching the given
    /// destination. A count of `0` removes the badge, matching SwiftUI's
    /// `badge(_:)` behavior.
    ///
    /// - Parameters:
    ///   - count: The badge count. `0` clears the badge.
    ///   - tab: The destination meta of the tab to badge.
    /// - Returns: `self` for chaining.
    @discardableResult
    func setBadge(_ count: Int, for tab: Destinations.Meta) -> Self {
        setBadge(count == 0 ? nil : String(count), for: tab)
    }

    /// Returns the badge currently set on the **first** tab matching the
    /// given destination, if any.
    func badge(for tab: Destinations.Meta) -> String? {
        _ = anyTabItems // resolve tabs before the first render if needed
        return tabItems.badge(forFirst: tab)
    }

    /// Returns whether the given destination is currently present in the
    /// tab bar.
    func isInTabItems(_ meta: Destinations.Meta) -> Bool {
        tabItems.tabs.contains { tab in
            guard let tabMeta = tab.meta as? Self.Destinations.Meta else { return false }
            return tabMeta == meta
        }
    }
}

@MainActor
public extension TabCoordinatable {
    /// Selects the **first** tab matching the given destination and
    /// invokes a typed callback with the tab's child coordinator, if any.
    @discardableResult
    func selectFirstTab<T: Coordinatable>(
        _ tab: Destinations.Meta,
        _ action: @escaping @MainActor (T) -> Void
    ) -> Self {
        _ = anyTabItems // resolve tabs so cold-launch deep links fire the callback
        if let dest = tabItems.select(first: tab),
           let coordinator = dest.coordinatable as? T {
            action(coordinator)
        }
        return self
    }

    /// Selects the **last** tab matching the given destination and
    /// invokes a typed callback with the tab's child coordinator, if any.
    @discardableResult
    func selectLastTab<T: Coordinatable>(
        _ tab: Destinations.Meta,
        _ action: @escaping @MainActor (T) -> Void
    ) -> Self {
        _ = anyTabItems // resolve tabs so cold-launch deep links fire the callback
        if let dest = tabItems.select(last: tab),
           let coordinator = dest.coordinatable as? T {
            action(coordinator)
        }
        return self
    }

    /// Selects a tab by index and invokes a typed callback with the
    /// tab's child coordinator, if any.
    @discardableResult
    func select<T: Coordinatable>(
        index: Int,
        _ action: @escaping @MainActor (T) -> Void
    ) -> Self {
        _ = anyTabItems // resolve tabs so cold-launch deep links fire the callback
        if let dest = tabItems.select(index),
           let coordinator = dest.coordinatable as? T {
            action(coordinator)
        }
        return self
    }

    /// Selects a tab by identifier and invokes a typed callback with the
    /// tab's child coordinator, if any.
    @discardableResult
    func select<T: Coordinatable>(
        id: UUID,
        _ action: @escaping @MainActor (T) -> Void
    ) -> Self {
        _ = anyTabItems // resolve tabs so cold-launch deep links fire the callback
        if let dest = tabItems.select(id),
           let coordinator = dest.coordinatable as? T {
            action(coordinator)
        }
        return self
    }

    /// Appends a tab and invokes a typed callback with the new tab's
    /// child coordinator, if any.
    @discardableResult
    func appendTab<T: Coordinatable>(
        _ tab: Destinations,
        _ action: @escaping @MainActor (T) -> Void
    ) -> Self {
        let resolved = tab.resolvedValue(for: self)
        resolved.coordinatable?.setHasLayerNavigationCoordinatable(self.hasLayerNavigationCoordinatable)
        resolved.coordinatable?.setParent(self)

        let appended = tabItems.appendTab(resolved)
        if let coordinator = appended.coordinatable as? T {
            action(coordinator)
        }
        return self
    }

    /// Inserts a tab at the given index and invokes a typed callback with
    /// the new tab's child coordinator, if any.
    @discardableResult
    func insertTab<T: Coordinatable>(
        _ tab: Destinations,
        at index: Int,
        _ action: @escaping @MainActor (T) -> Void
    ) -> Self {
        let resolved = tab.resolvedValue(for: self)
        resolved.coordinatable?.setHasLayerNavigationCoordinatable(self.hasLayerNavigationCoordinatable)
        resolved.coordinatable?.setParent(self)

        let inserted = tabItems.insertTab(resolved, at: index)
        if let coordinator = inserted.coordinatable as? T {
            action(coordinator)
        }
        return self
    }
}

@MainActor
public extension TabCoordinatable {
    /// Presents a destination modally on this tab coordinator.
    ///
    /// The modal lives on this coordinator's container and is rendered
    /// as a sheet or full-screen cover above the `TabView`.
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
    /// The callback fires once after the modal lands above the `TabView`,
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

    /// Whether this coordinator currently presents a modal (sheet or
    /// full-screen cover) above the `TabView`.
    var isPresentingModal: Bool {
        !anyTabItems.modals.isEmpty
    }
}

// MARK: - Typed child resolution

@MainActor
public extension TabCoordinatable {
    /// Selects the **first** tab matching the given destination and
    /// returns the tab's child coordinator, if any.
    ///
    /// A non-closure alternative to ``selectFirstTab(_:_:)`` that
    /// flattens deep-link chains — see
    /// ``RootCoordinatable/setRoot(_:animation:expecting:)``.
    func selectFirstTab<T: Coordinatable>(
        _ tab: Destinations.Meta,
        expecting coordinatorType: T.Type
    ) -> T? {
        _ = anyTabItems // resolve tabs so cold-launch deep links work
        return tabItems.select(first: tab)?.coordinatable as? T
    }

    /// Selects the **last** tab matching the given destination and
    /// returns the tab's child coordinator, if any.
    func selectLastTab<T: Coordinatable>(
        _ tab: Destinations.Meta,
        expecting coordinatorType: T.Type
    ) -> T? {
        _ = anyTabItems // resolve tabs so cold-launch deep links work
        return tabItems.select(last: tab)?.coordinatable as? T
    }

    /// Selects a tab by index and returns the tab's child coordinator,
    /// if any.
    func select<T: Coordinatable>(
        index: Int,
        expecting coordinatorType: T.Type
    ) -> T? {
        _ = anyTabItems // resolve tabs so cold-launch deep links work
        return tabItems.select(index)?.coordinatable as? T
    }

    /// Selects a tab by identifier and returns the tab's child
    /// coordinator, if any.
    func select<T: Coordinatable>(
        id: UUID,
        expecting coordinatorType: T.Type
    ) -> T? {
        _ = anyTabItems // resolve tabs so cold-launch deep links work
        return tabItems.select(id)?.coordinatable as? T
    }

    /// Appends a tab and returns the new tab's child coordinator, if any.
    func appendTab<T: Coordinatable>(
        _ tab: Destinations,
        expecting coordinatorType: T.Type
    ) -> T? {
        let resolved = tab.resolvedValue(for: self)
        resolved.coordinatable?.setHasLayerNavigationCoordinatable(self.hasLayerNavigationCoordinatable)
        resolved.coordinatable?.setParent(self)
        return tabItems.appendTab(resolved).coordinatable as? T
    }

    /// Inserts a tab at the given index and returns the new tab's child
    /// coordinator, if any.
    func insertTab<T: Coordinatable>(
        _ tab: Destinations,
        at index: Int,
        expecting coordinatorType: T.Type
    ) -> T? {
        let resolved = tab.resolvedValue(for: self)
        resolved.coordinatable?.setHasLayerNavigationCoordinatable(self.hasLayerNavigationCoordinatable)
        resolved.coordinatable?.setParent(self)
        return tabItems.insertTab(resolved, at: index).coordinatable as? T
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
}

// MARK: - Awaitable presentation

@MainActor
public extension TabCoordinatable {
    /// Presents a destination modally and suspends until it is dismissed.
    ///
    /// See ``FlowCoordinatable/presentAndWait(_:as:policy:)`` — identical
    /// semantics, hosted above the `TabView`.
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
    /// identical semantics, hosted above the `TabView`.
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
extension TabCoordinatable {
    func modalPolicySkips(_ destination: Destinations, policy: RoutePolicy) -> Bool {
        guard case .distinct = policy else { return false }
        return anyTabItems.modals.contains { dest in
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
        }

        anyTabItems.modals.append(dest)
        return dest
    }
}

public extension TabCoordinatable {
    func setPresentedAs(_ type: PresentationType) {
        anyTabItems.presentedAs = type
        for i in anyTabItems.tabs.indices {
            if anyTabItems.tabs[i].pushType == nil {
                anyTabItems.tabs[i].setPushType(type)
            }
        }
    }
}

/// The SwiftUI view generated by a ``TabCoordinatable`` coordinator.
///
/// You never create this view directly — access ``Coordinatable/view``
/// on a `TabCoordinatable` coordinator to obtain it.
public struct TabCoordinatableView: CoordinatableView {
    private let _coordinator: any TabCoordinatable

    public var coordinator: any Coordinatable {
        _coordinator
    }

    init(coordinator: any TabCoordinatable) {
        self._coordinator = coordinator
    }

    @ViewBuilder
    private func flowCoordinatableView() -> some View {
        if #available(iOS 18, macOS 15, *) {
            flowCoordinatableViewiOS18()
        } else {
            flowCoordinatableViewiOS17()
        }
    }

    @available(iOS 18, macOS 15, *)
    private func flowCoordinatableViewiOS18() -> some View {
        TabView(selection: _coordinator.selectedTabBinding) {
            ForEach(_coordinator.anyTabItems.tabs) { tab in
                Tab(value: tab.id, role: tab.tabRole) {
                    wrappedView(tab)
                        .environmentCoordinatable(_coordinator)
                        .badge(tab.badge.map(Text.init))
#if os(iOS)
                        .toolbar(_coordinator.anyTabItems.tabBarVisibility, for: .tabBar)
#endif
                } label: {
                    if let tabItem = tab.tabItem {
                        AnyView(tabItem)
                    }
                }
            }
        }
    }

    private func flowCoordinatableViewiOS17() -> some View {
        TabView(selection: _coordinator.selectedTabBinding) {
            ForEach(_coordinator.anyTabItems.tabs) { tab in
                wrappedView(tab)
                    .environmentCoordinatable(_coordinator)
                    .badge(tab.badge.map(Text.init))
                    .tabItem {
                        if let tabItem = tab.tabItem {
                            AnyView(tabItem)
                        }
                    }
                    .tag(tab.id)
            }
        }
    }

    private func modals(of type: ModalPresentationType) -> [Destination] {
        let target = type.presentationType
        return _coordinator.anyTabItems.modals.filter { $0.pushType == target }
    }

    public var body: some View {
        _coordinator.customize(
            AnyView(
                flowCoordinatableView()
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
        .id(_coordinator.anyTabItems.id)
    }
}
