//
//  TabCoordinatable.swift
//  Scaffolding
//
//  Created by Alexandr Valíček on 24.09.2025.
//

import SwiftUI
import Observation

/// A coordinator that renders a `TabView` whose tabs are destinations.
///
/// Each tab is a view or a child coordinator, usually a flow with its own
/// stack. Declare ``tabItems`` and tab routes that return content plus an
/// optional label or `TabRole`:
///
/// ```swift
/// @MainActor @Observable @Scaffoldable
/// final class MainTabCoordinator: @MainActor TabCoordinatable {
///     var tabItems = TabItems<MainTabCoordinator>(tabs: [.home, .settings])
///
///     func home() -> (any Coordinatable, some View) {
///         (HomeCoordinator(), Label("Home", systemImage: "house"))
///     }
///     func settings() -> (some View, some View) {
///         (SettingsView(), Label("Settings", systemImage: "gear"))
///     }
/// }
/// ```
///
/// Selecting a tab keeps its state; ``setTabs(_:)`` replaces it. Tab children
/// are structural and cannot dismiss themselves. See <doc:TabBars> and
/// <doc:DeepLinking>.
///
/// ## Topics
///
/// ### Selecting Tabs
///
/// - ``selectFirstTab(_:)``
/// - ``selectFirstTab(_:expecting:)``
/// - ``selectLastTab(_:)``
/// - ``selectLastTab(_:expecting:)``
/// - ``select(index:)``
/// - ``select(index:expecting:)``
/// - ``select(id:)``
/// - ``select(id:expecting:)``
/// - ``shouldSelect(tab:isReselection:)``
///
/// ### Reading Selection
///
/// - ``selectedTabDestination``
/// - ``selectedTabIndex``
/// - ``isInTabItems(_:)``
/// - ``tabItems``
///
/// ### Adding and Removing Tabs
///
/// - ``appendTab(_:)``
/// - ``appendTab(_:expecting:)``
/// - ``insertTab(_:at:)``
/// - ``insertTab(_:at:expecting:)``
/// - ``removeFirstTab(_:)``
/// - ``removeLastTab(_:)``
/// - ``setTabs(_:)``
///
/// ### Tab Appearance and Accessibility
///
/// - ``setBadge(_:for:)-6aae0``
/// - ``setBadge(_:for:)-8l4hz``
/// - ``badge(for:)``
/// - ``setTabAccessibilityIdentifier(_:for:)``
/// - ``tabAccessibilityIdentifier(for:)``
/// - ``setTabBarVisibility(_:)``
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
/// - ``anyTabItems``
///
/// ### Presentation Context
///
/// - ``setPresentedAs(_:)``
///
/// ### Deprecated Compatibility
///
/// - ``appendTab(_:_:)``
/// - ``insertTab(_:at:_:)``
/// - ``present(_:as:policy:onDismiss:)``
/// - ``present(_:as:policy:onDismiss:_:)``
/// - ``present(_:as:policy:onDismiss:expecting:)``
/// - ``presentAndWait(_:as:policy:)``
/// - ``select(id:_:)``
/// - ``select(index:_:)``
/// - ``selectFirstTab(_:_:)``
/// - ``selectLastTab(_:_:)``
@MainActor
public protocol TabCoordinatable: Coordinatable where ViewType == TabCoordinatableView {
    /// The container holding this coordinator's tabs, selection, and modal requests.
    var tabItems: TabItems<Self> { get }

    /// The tab container as a read-only, type-erased value, with initial tabs resolved.
    var anyTabItems: any AnyTabItems { get }

    /// Framework plumbing: the container without resolving its initial tabs.
    var _uninitializedTabItems: any AnyTabItems { get }

    /// Decides whether a user tap selects `tab`.
    ///
    /// Return `false` to keep the current tab — for example, to present a login
    /// sheet instead. To redirect, select another tab inside the hook and return
    /// `false`.
    ///
    /// A tap on the already-selected tab calls the hook with
    /// `isReselection == true` and ignores the return value. Use it for
    /// pop-to-root or scroll-to-top.
    ///
    /// Programmatic selection, such as ``selectFirstTab(_:)``, bypasses the hook.
    /// The default implementation returns `true`. See <doc:TabBars#Intercept-taps>.
    ///
    /// - Parameters:
    ///   - tab: The tapped tab's case.
    ///   - isReselection: Whether the tab is already selected.
    /// - Returns: Whether to select the tab. Ignored on reselection.
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

    var _uninitializedTabItems: any AnyTabItems { tabItems }

    var anyTabItems: any AnyTabItems {
        tabItems.setup(for: self)
        return tabItems
    }

    /// The rendered tab coordinator and everything below it.
    ///
    /// Show the top-level coordinator's `view` once, usually in a `WindowGroup`.
    /// Child coordinators render through their parent.
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
        updateNavigationContext(navigationLayer: value, presentation: inheritedPresentation)
    }

    func setParent(_ parent: any Coordinatable) {
        tabItems.setParent(parent)
    }

    /// Shows or hides the native tab bar.
    ///
    /// Takes effect on iOS, iPadOS, and Mac Catalyst. Hide it when you render a
    /// custom bar; see <doc:TabBars#Build-a-custom-bar>.
    ///
    /// - Parameter value: `.automatic`, `.visible`, or `.hidden`.
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
    /// Selects the first tab whose case matches `tab`.
    ///
    /// Does nothing when no tab matches. Bypasses
    /// ``shouldSelect(tab:isReselection:)``.
    ///
    /// - Parameter tab: The tab case to select.
    /// - Returns: `self` for chaining.
    @discardableResult
    func selectFirstTab(_ tab: Destinations.Meta) -> Self {
        let _ = tabItems.select(first: tab)
        return self
    }

    /// Selects the last tab whose case matches `tab`.
    ///
    /// Does nothing when no tab matches. Bypasses
    /// ``shouldSelect(tab:isReselection:)``.
    ///
    /// - Parameter tab: The tab case to select.
    /// - Returns: `self` for chaining.
    @discardableResult
    func selectLastTab(_ tab: Destinations.Meta) -> Self {
        let _ = tabItems.select(last: tab)
        return self
    }

    /// Selects the tab at a zero-based position.
    ///
    /// Does nothing when `index` is out of range. Bypasses
    /// ``shouldSelect(tab:isReselection:)``.
    ///
    /// - Parameter index: The tab's position.
    /// - Returns: `self` for chaining.
    @discardableResult
    func select(index: Int) -> Self {
        let _ = tabItems.select(index)
        return self
    }

    /// Selects the tab with the given destination identifier.
    ///
    /// Does nothing when no tab has `id`. Bypasses
    /// ``shouldSelect(tab:isReselection:)``.
    ///
    /// - Parameter id: A tab's ``Destination/id``.
    /// - Returns: `self` for chaining.
    @discardableResult
    func select(id: UUID) -> Self {
        let _ = tabItems.select(id)
        return self
    }

    /// Replaces every tab with fresh destinations.
    ///
    /// The old tabs are torn down: their navigation state, badges, and
    /// identifiers are discarded, and awaiting callers inside them resume with
    /// `nil`. The first new tab is selected. To keep a tab's history, select it
    /// instead.
    ///
    /// - Parameter tabs: The new tab cases, in display order.
    /// - Returns: `self` for chaining.
    @discardableResult
    func setTabs(_ tabs: [Destinations]) -> Self {
        guard tabs.allSatisfy(\.isAvailable) else { return self }
        tabItems.setup(for: self)
        let tabs = tabs.map {
            let t = $0.resolvedValue(for: self)
            t.coordinatable?.attach(to: self, navigationLayer: hasLayerNavigationCoordinatable, presentation: tabItems.presentedAs)
            return t
        }

        tabItems.setTabs(tabs)

        return self
    }

    /// Adds a tab at the end.
    ///
    /// Selects it when no tab is selected.
    ///
    /// - Parameter tab: The tab case to add.
    /// - Returns: `self` for chaining.
    @discardableResult
    func appendTab(_ tab: Destinations) -> Self {
        guard tab.isAvailable else { return self }
        tabItems.setup(for: self)
        let tab = tab.resolvedValue(for: self)
        tab.coordinatable?.attach(to: self, navigationLayer: hasLayerNavigationCoordinatable, presentation: tabItems.presentedAs)

        let _ = tabItems.appendTab(tab)

        return self
    }

    /// Inserts a tab at a position.
    ///
    /// Selects it when no tab is selected.
    ///
    /// - Parameters:
    ///   - tab: The tab case to insert.
    ///   - index: The position, clamped to the valid range.
    /// - Returns: `self` for chaining.
    @discardableResult
    func insertTab(_ tab: Destinations, at index: Int) -> Self {
        guard tab.isAvailable else { return self }
        tabItems.setup(for: self)
        let tab = tab.resolvedValue(for: self)
        tab.coordinatable?.attach(to: self, navigationLayer: hasLayerNavigationCoordinatable, presentation: tabItems.presentedAs)

        let _ = tabItems.insertTab(tab, at: index)

        return self
    }

    /// Removes the first tab whose case matches `meta`.
    ///
    /// The removed tab is torn down, and awaiting callers inside it resume with
    /// `nil`. If it was selected, the next tab is selected, or the previous one
    /// when it was last. Does nothing when no tab matches.
    ///
    /// - Parameter meta: The tab case to remove.
    /// - Returns: `self` for chaining.
    @discardableResult
    func removeFirstTab(_ meta: Destinations.Meta) -> Self {
        tabItems.setup(for: self)
        tabItems.removeFirstTab(meta)
        return self
    }

    /// Removes the last tab whose case matches `meta`.
    ///
    /// The removed tab is torn down, and awaiting callers inside it resume with
    /// `nil`. If it was selected, the next tab is selected, or the previous one
    /// when it was last. Does nothing when no tab matches.
    ///
    /// - Parameter meta: The tab case to remove.
    /// - Returns: `self` for chaining.
    @discardableResult
    func removeLastTab(_ meta: Destinations.Meta) -> Self {
        tabItems.setup(for: self)
        tabItems.removeLastTab(meta)
        return self
    }

    /// Sets or clears the badge on the first tab whose case matches `tab`.
    ///
    /// ```swift
    /// tabs.setBadge("New", for: .inbox)
    /// tabs.setBadge(nil, for: .inbox)   // clear
    /// ```
    ///
    /// The tab keeps its content and state. Does nothing when no tab matches.
    /// Badges do not render on tvOS or watchOS.
    ///
    /// - Parameters:
    ///   - value: The badge text, or `nil` to clear it.
    ///   - tab: The tab case.
    /// - Returns: `self` for chaining.
    @discardableResult
    func setBadge(_ value: String?, for tab: Destinations.Meta) -> Self {
        _ = _resolvedTabItems // resolve tabs before the first render if needed
        tabItems.setBadge(value, forFirst: tab)
        return self
    }

    /// Sets a numeric badge on the first tab whose case matches `tab`.
    ///
    /// A count of `0` clears the badge, as SwiftUI's `badge(_:)` does.
    ///
    /// - Parameters:
    ///   - count: The badge count; `0` clears it.
    ///   - tab: The tab case.
    /// - Returns: `self` for chaining.
    @discardableResult
    func setBadge(_ count: Int, for tab: Destinations.Meta) -> Self {
        setBadge(count == 0 ? nil : String(count), for: tab)
    }

    /// Returns the badge on the first tab whose case matches `tab`.
    ///
    /// Returns `nil` when that tab has no badge or no tab matches.
    func badge(for tab: Destinations.Meta) -> String? {
        _ = _resolvedTabItems // resolve tabs before the first render if needed
        return tabItems.badge(forFirst: tab)
    }

    /// Sets or clears the accessibility identifier on the first tab whose case
    /// matches `tab`.
    ///
    /// The identifier reaches the native tab bar item, so UI tests can find the
    /// tab regardless of its localized label. An identifier on the label view
    /// does not.
    ///
    /// ```swift
    /// tabs.setTabAccessibilityIdentifier("tab.home", for: .home)
    /// ```
    ///
    /// With a custom bar, apply ``tabAccessibilityIdentifier(for:)`` to your own
    /// button. Does nothing when no tab matches.
    ///
    /// - Parameters:
    ///   - identifier: The identifier, or `nil` to clear it.
    ///   - tab: The tab case.
    /// - Returns: `self` for chaining.
    @discardableResult
    func setTabAccessibilityIdentifier(_ identifier: String?, for tab: Destinations.Meta) -> Self {
        _ = _resolvedTabItems // resolve tabs before the first render if needed
        tabItems.setTabAccessibilityIdentifier(identifier, forFirst: tab)
        return self
    }

    /// Returns the accessibility identifier on the first tab whose case matches
    /// `tab`.
    ///
    /// Returns `nil` when that tab has none or no tab matches.
    func tabAccessibilityIdentifier(for tab: Destinations.Meta) -> String? {
        _ = _resolvedTabItems // resolve tabs before the first render if needed
        return tabItems.tabAccessibilityIdentifier(forFirst: tab)
    }

    /// The position of the selected tab, or `nil` when there are no tabs.
    ///
    /// Resolves the initial tabs if needed, so it is valid before the first render.
    var selectedTabIndex: Int? {
        _resolvedTabItems.tabs.firstIndex { $0.id == tabItems.selectedTab }
    }

    /// The case of the selected tab, or `nil` when there are no tabs.
    ///
    /// Compare it directly: `selectedTabDestination == .home`. Resolves the
    /// initial tabs if needed.
    var selectedTabDestination: Destinations.Meta? {
        guard let index = selectedTabIndex else { return nil }
        return tabItems.tabs[index].meta as? Destinations.Meta
    }

    /// Returns whether any tab has the case `meta`.
    func isInTabItems(_ meta: Destinations.Meta) -> Bool {
        _resolvedTabItems.tabs.contains { tab in
            guard let tabMeta = tab.meta as? Self.Destinations.Meta else { return false }
            return tabMeta == meta
        }
    }
}

@MainActor
public extension TabCoordinatable {
    /// Deprecated. Use ``selectFirstTab(_:expecting:)`` instead.
    ///
    /// The replacement returns the child instead of calling a closure.
    @discardableResult
    @available(*, deprecated, message: "Will be removed in a future update. Use the expecting: overload to access the child coordinator.")
    func selectFirstTab<T: Coordinatable>(
        _ tab: Destinations.Meta,
        _ action: @escaping @MainActor (T) -> Void
    ) -> Self {
        _ = _resolvedTabItems // resolve tabs so cold-launch deep links fire the callback
        if let dest = tabItems.select(first: tab),
           let coordinator = dest.coordinatable as? T {
            action(coordinator)
        }
        return self
    }

    /// Deprecated. Use ``selectLastTab(_:expecting:)`` instead.
    ///
    /// The replacement returns the child instead of calling a closure.
    @discardableResult
    @available(*, deprecated, message: "Will be removed in a future update. Use the expecting: overload to access the child coordinator.")
    func selectLastTab<T: Coordinatable>(
        _ tab: Destinations.Meta,
        _ action: @escaping @MainActor (T) -> Void
    ) -> Self {
        _ = _resolvedTabItems // resolve tabs so cold-launch deep links fire the callback
        if let dest = tabItems.select(last: tab),
           let coordinator = dest.coordinatable as? T {
            action(coordinator)
        }
        return self
    }

    /// Deprecated. Use ``select(index:expecting:)`` instead.
    ///
    /// The replacement returns the child instead of calling a closure.
    @discardableResult
    @available(*, deprecated, message: "Will be removed in a future update. Use the expecting: overload to access the child coordinator.")
    func select<T: Coordinatable>(
        index: Int,
        _ action: @escaping @MainActor (T) -> Void
    ) -> Self {
        _ = _resolvedTabItems // resolve tabs so cold-launch deep links fire the callback
        if let dest = tabItems.select(index),
           let coordinator = dest.coordinatable as? T {
            action(coordinator)
        }
        return self
    }

    /// Deprecated. Use ``select(id:expecting:)`` instead.
    ///
    /// The replacement returns the child instead of calling a closure.
    @discardableResult
    @available(*, deprecated, message: "Will be removed in a future update. Use the expecting: overload to access the child coordinator.")
    func select<T: Coordinatable>(
        id: UUID,
        _ action: @escaping @MainActor (T) -> Void
    ) -> Self {
        _ = _resolvedTabItems // resolve tabs so cold-launch deep links fire the callback
        if let dest = tabItems.select(id),
           let coordinator = dest.coordinatable as? T {
            action(coordinator)
        }
        return self
    }

    /// Deprecated. Use ``appendTab(_:expecting:)`` instead.
    ///
    /// The replacement returns the child instead of calling a closure.
    @discardableResult
    @available(*, deprecated, message: "Will be removed in a future update. Use the expecting: overload to access the child coordinator.")
    func appendTab<T: Coordinatable>(
        _ tab: Destinations,
        _ action: @escaping @MainActor (T) -> Void
    ) -> Self {
        guard tab.isAvailable else { return self }
        tabItems.setup(for: self)
        let resolved = tab.resolvedValue(for: self)
        resolved.coordinatable?.attach(to: self, navigationLayer: hasLayerNavigationCoordinatable, presentation: tabItems.presentedAs)

        let appended = tabItems.appendTab(resolved)
        if let coordinator = appended.coordinatable as? T {
            action(coordinator)
        }
        return self
    }

    /// Deprecated. Use ``insertTab(_:at:expecting:)`` instead.
    ///
    /// The replacement returns the child instead of calling a closure.
    @discardableResult
    @available(*, deprecated, message: "Will be removed in a future update. Use the expecting: overload to access the child coordinator.")
    func insertTab<T: Coordinatable>(
        _ tab: Destinations,
        at index: Int,
        _ action: @escaping @MainActor (T) -> Void
    ) -> Self {
        guard tab.isAvailable else { return self }
        tabItems.setup(for: self)
        let resolved = tab.resolvedValue(for: self)
        resolved.coordinatable?.attach(to: self, navigationLayer: hasLayerNavigationCoordinatable, presentation: tabItems.presentedAs)

        let inserted = tabItems.insertTab(resolved, at: index)
        if let coordinator = inserted.coordinatable as? T {
            action(coordinator)
        }
        return self
    }
}

@MainActor
public extension TabCoordinatable {
    /// Presents a destination as a sheet or full-screen cover above the tabs.
    ///
    /// Requests queue on this coordinator: the first renders and later ones wait.
    /// Add `expecting:` for the child or `awaiting:` for a result; see
    /// <doc:ModalsAndResults>.
    ///
    /// - Parameters:
    ///   - destination: The route to present.
    ///   - type: `.sheet` (the default) or `.fullScreenCover`. Covers render as
    ///     sheets on macOS.
    ///   - policy: ``RoutePolicy/distinct`` skips a case this coordinator already
    ///     requested, including queued requests. Associated values are ignored.
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
    /// Pass `Void.self` to wait for dismissal only.
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

    /// Whether this coordinator has a modal request, visible or queued.
    var isPresentingModal: Bool {
        !_resolvedTabItems.modals.isEmpty
    }
}

// MARK: - Typed child resolution

@MainActor
public extension TabCoordinatable {
    /// Selects the first tab whose case matches `tab` and returns its child as
    /// `T`, or `nil` for a view route or another type. The navigation happens
    /// either way.
    ///
    /// Returns `nil` and changes nothing when no tab matches. Resolves the
    /// initial tabs first, so it works on a cold launch. See <doc:DeepLinking>.
    func selectFirstTab<T: Coordinatable>(
        _ tab: Destinations.Meta,
        expecting coordinatorType: T.Type
    ) -> T? {
        _ = _resolvedTabItems // resolve tabs so cold-launch deep links work
        return tabItems.select(first: tab)?.coordinatable as? T
    }

    /// Selects the last tab whose case matches `tab` and returns its child as
    /// `T`, or `nil` for a view route or another type. The navigation happens
    /// either way.
    ///
    /// Returns `nil` and changes nothing when no tab matches. Resolves the
    /// initial tabs first, so it works on a cold launch.
    func selectLastTab<T: Coordinatable>(
        _ tab: Destinations.Meta,
        expecting coordinatorType: T.Type
    ) -> T? {
        _ = _resolvedTabItems // resolve tabs so cold-launch deep links work
        return tabItems.select(last: tab)?.coordinatable as? T
    }

    /// Selects the tab at `index` and returns its child as `T`, or `nil` for a
    /// view route or another type. The navigation happens either way.
    ///
    /// Returns `nil` and changes nothing when `index` is out of range.
    func select<T: Coordinatable>(
        index: Int,
        expecting coordinatorType: T.Type
    ) -> T? {
        _ = _resolvedTabItems // resolve tabs so cold-launch deep links work
        return tabItems.select(index)?.coordinatable as? T
    }

    /// Selects the tab with `id` and returns its child as `T`, or `nil` for a
    /// view route or another type. The navigation happens either way.
    ///
    /// Returns `nil` and changes nothing when no tab has `id`.
    func select<T: Coordinatable>(
        id: UUID,
        expecting coordinatorType: T.Type
    ) -> T? {
        _ = _resolvedTabItems // resolve tabs so cold-launch deep links work
        return tabItems.select(id)?.coordinatable as? T
    }

    /// Adds a tab at the end and returns its child as `T`, or `nil` for a view
    /// route or another type. The tab is added either way.
    ///
    /// Selects the tab when no tab is selected.
    func appendTab<T: Coordinatable>(
        _ tab: Destinations,
        expecting coordinatorType: T.Type
    ) -> T? {
        guard tab.isAvailable else { return nil }
        tabItems.setup(for: self)
        let resolved = tab.resolvedValue(for: self)
        resolved.coordinatable?.attach(to: self, navigationLayer: hasLayerNavigationCoordinatable, presentation: tabItems.presentedAs)
        return tabItems.appendTab(resolved).coordinatable as? T
    }

    /// Inserts a tab at `index` and returns its child as `T`, or `nil` for a view
    /// route or another type. The tab is added either way.
    ///
    /// `index` is clamped to the valid range. Selects the tab when no tab is
    /// selected.
    func insertTab<T: Coordinatable>(
        _ tab: Destinations,
        at index: Int,
        expecting coordinatorType: T.Type
    ) -> T? {
        guard tab.isAvailable else { return nil }
        tabItems.setup(for: self)
        let resolved = tab.resolvedValue(for: self)
        resolved.coordinatable?.attach(to: self, navigationLayer: hasLayerNavigationCoordinatable, presentation: tabItems.presentedAs)
        return tabItems.insertTab(resolved, at: index).coordinatable as? T
    }

    /// Presents a destination above the tabs and returns the child as `T`, or
    /// `nil` for a view route or another type. The navigation happens either way.
    ///
    /// Returns `nil` without presenting when ``RoutePolicy/distinct`` skips the
    /// request.
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
    /// Await the returned `result()` for dismissal or a value.
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
}

// MARK: - Awaitable presentation

@MainActor
public extension TabCoordinatable {
    /// Presents a destination above the tabs and returns its child and a result
    /// waiter without suspending.
    ///
    /// Configure `coordinator`, then call `await result()`. `coordinator` is `nil`
    /// for a view route or another type. A ``RoutePolicy/distinct`` skip or an
    /// already-cancelled task presents nothing and returns a `nil` child and a
    /// `nil` result. See ``Coordinatable/present(_:as:policy:expecting:awaiting:)``.
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

    /// Deprecated. Use ``Coordinatable/present(_:as:policy:awaiting:)`` instead.
    ///
    /// Pass `awaiting: Void.self` to wait for dismissal only.
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

    /// Presents a destination above the tabs and suspends until it leaves.
    ///
    /// Returns the value passed to ``Coordinatable/dismissCoordinator(returning:)``
    /// or ``Destination/dismiss(returning:)``. Returns `nil` for an ordinary
    /// dismissal, a mismatched type, a ``RoutePolicy/distinct`` skip, or a
    /// cancelled task. Cancellation leaves the modal in place. See
    /// <doc:ModalsAndResults>.
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
extension TabCoordinatable {
    func modalPolicySkips(_ destination: Destinations, policy: RoutePolicy) -> Bool {
        guard destination.isAvailable else { return true }
        guard case .distinct = policy else { return false }
        return _resolvedTabItems.modals.contains { dest in
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

        withNavigationAnimation { tabItems.modals.append(dest) }
        return dest
    }
}

public extension TabCoordinatable {
    /// Records the presentation style inherited from the parent.
    ///
    /// The framework calls this; apps don't need to.
    func setPresentedAs(_ type: PresentationType) {
        inheritPresentation(type)
    }
}

/// Invisible helper that observes tab badges from its own view node and
/// bumps ``TabCoordinatableView``'s local state when they change.
///
/// `TabView` (iOS 26) does not reliably re-evaluate the tab container's
/// body when a badge mutates on the observable ``TabItems`` — writes after
/// the first couple of renders stop invalidating it. Views in the content
/// hierarchy keep observing correctly, so this node re-renders on every
/// badge change and converts it into a `@State` write, which SwiftUI always
/// honors with a re-render of the owning view.
private struct TabMetadataSync: View {
    let coordinator: any TabCoordinatable
    @Binding var trigger: Int

    private var metadata: [[String?]] {
        coordinator._resolvedTabItems.tabs.map { [$0.badge, $0.accessibilityIdentifier] }
    }

    var body: some View {
        Color.clear
            .onChange(of: metadata) {
                trigger &+= 1
            }
    }
}

/// The view a ``TabCoordinatable`` renders.
///
/// Get it from ``Coordinatable/view``; don't create it directly.
public struct TabCoordinatableView: CoordinatableView {
    private let _coordinator: any TabCoordinatable

    /// Bumped by ``TabMetadataSync`` whenever a tab badge changes. `TabView`
    /// does not reliably re-evaluate this view's body when a badge mutates
    /// on the observable ``TabItems`` (observed on iOS 26); state changes
    /// always invalidate, so this guarantees the new badge is applied.
    @State private var metadataRefreshTrigger = 0

    public var coordinator: any Coordinatable {
        _coordinator
    }

    init(coordinator: any TabCoordinatable) {
        self._coordinator = coordinator
    }

    private func flowCoordinatableView() -> some View {
        TabView(selection: _coordinator.selectedTabBinding) {
            // Metadata updates must preserve the lifetime of the tab content.
            ForEach(_coordinator._resolvedTabItems.tabs) { tab in
                Tab(value: tab.id, role: tab.tabRole) {
                    wrappedView(tab)
                        .environmentCoordinatable(_coordinator)
#if os(iOS)
                        .background(NativeTabMetadata(coordinator: _coordinator).frame(width: 0, height: 0))
                        .toolbar(_coordinator._resolvedTabItems.tabBarVisibility, for: .tabBar)
#endif
                } label: {
                    if let tabItem = tab.tabItem {
                        AnyView(tabItem)
                    }
                }
                // With the Tab builder API the badge must be applied to the
                // TabContent, not the content view — the view-level modifier
                // is ignored inside `Tab { }`.
#if !os(tvOS) && !os(watchOS)
                .badge(tab.badge.map(Text.init))
#endif
                // Likewise for the accessibility identifier: only the
                // TabContent modifier reaches the rendered tab bar item.
                .accessibilityIdentifier(
                    tab.accessibilityIdentifier ?? "",
                    isEnabled: tab.accessibilityIdentifier != nil
                )
            }
        }
        .background(TabMetadataSync(coordinator: _coordinator, trigger: $metadataRefreshTrigger))
    }

    public var body: some View {
        // Reading the value registers this body as a dependency. Passing only
        // its Binding to TabMetadataSync does not subscribe to state changes.
        let _ = metadataRefreshTrigger
        _coordinator.customize(
            AnyView(
                flowCoordinatableView()
            )
        )
        .applyContainerModals(
            destinations: _coordinator._resolvedTabItems.modals,
            onDismissSheet: { id in (_coordinator as any Coordinatable).removeContainerModal(id: id, type: .sheet) },
            onDismissFullScreenCover: { id in (_coordinator as any Coordinatable).removeContainerModal(id: id, type: .fullScreenCover) },
            modalContent: wrappedView
        )
        .environmentCoordinatable(coordinator)
        .id(_coordinator._resolvedTabItems.id)
    }
}

@MainActor
extension TabCoordinatable {
    var _tabItems: any _MutableTabItems { tabItems }
    var _resolvedTabItems: any _MutableTabItems {
        tabItems.setup(for: self)
        return tabItems
    }
}

@MainActor
public extension TabCoordinatable {
    /// Sets the default animation for this coordinator's navigation changes. Pass `nil` to disable it.
    func setTransitionAnimation(_ animation: Animation?) { tabItems.animation = animation }
}
