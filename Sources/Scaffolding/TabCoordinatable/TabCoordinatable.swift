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
/// ``Scaffoldable()`` macro.
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

    func view() -> TabCoordinatableView {
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
            set: { self.tabItems.selectedTab = $0 }
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

    /// Selects the **first** tab matching the given destination and passes
    /// it to a callback.
    @discardableResult
    func selectFirstTab<T>(
        _ tab: Destinations.Meta,
        value: @escaping (T) -> Void
    ) -> Self {
        let tab = tabItems.select(first: tab)

        guard let tab else { return self }

        if tab.coordinatable != nil, let coordinatable = tab.coordinatable as? T {
            value(coordinatable)
        } else if let view = tab.view as? T {
            value(view)
        } else {
            fatalError("Could not cast to type \(T.self)")
        }

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

    /// Selects the **last** tab matching the given destination and passes
    /// it to a callback.
    @discardableResult
    func selectLastTab<T>(
        _ tab: Destinations.Meta,
        value: @escaping (T) -> Void
    ) -> Self {
        let tab = tabItems.select(last: tab)

        guard let tab else { return self }

        if tab.coordinatable != nil, let coordinatable = tab.coordinatable as? T {
            value(coordinatable)
        } else if let view = tab.view as? T {
            value(view)
        } else {
            fatalError("Could not cast to type \(T.self)")
        }

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

    /// Selects a tab by index and passes it to a callback.
    @discardableResult
    func select<T>(
        index: Int,
        value: @escaping (T) -> Void
    ) -> Self {
        let tab = tabItems.select(index)

        guard let tab else { return self }

        if tab.coordinatable != nil, let coordinatable = tab.coordinatable as? T {
            value(coordinatable)
        } else if let view = tab.view as? T {
            value(view)
        } else {
            fatalError("Could not cast to type \(T.self)")
        }

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

    /// Selects a tab by UUID and passes it to a callback.
    @discardableResult
    func select<T>(
        id: UUID,
        value: @escaping (T) -> Void
    ) -> Self {
        let tab = tabItems.select(id)

        guard let tab else { return self }

        if tab.coordinatable != nil, let coordinatable = tab.coordinatable as? T {
            value(coordinatable)
        } else if let view = tab.view as? T {
            value(view)
        } else {
            fatalError("Could not cast to type \(T.self)")
        }

        return self
    }

    /// Replaces all tabs with the given destinations.
    ///
    /// - Parameter tabs: The new set of tab destinations.
    /// - Returns: `self` for chaining.
    @discardableResult
    func setTabs(_ tabs: [Destinations]) -> Self {
        let tabs = tabs.map {
            let t = $0.value(for: self)
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
        let tab = tab.value(for: self)
        tab.coordinatable?.setHasLayerNavigationCoordinatable(self.hasLayerNavigationCoordinatable)
        tab.coordinatable?.setParent(self)

        let _ = tabItems.appendTab(tab)

        return self
    }

    /// Appends a new tab and passes it to a callback.
    @discardableResult
    func appendTab<T>(
        _ tab: Destinations,
        value: @escaping (T) -> Void
    ) -> Self {
        let t = tab.value(for: self)
        t.coordinatable?.setHasLayerNavigationCoordinatable(self.hasLayerNavigationCoordinatable)
        t.coordinatable?.setParent(self)

        let tab = tabItems.appendTab(t)

        if tab.coordinatable != nil, let coordinatable = tab.coordinatable as? T {
            value(coordinatable)
        } else if let view = tab.view as? T {
            value(view)
        } else {
            fatalError("Could not cast to type \(T.self)")
        }

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
        let tab = tab.value(for: self)
        tab.coordinatable?.setHasLayerNavigationCoordinatable(self.hasLayerNavigationCoordinatable)
        tab.coordinatable?.setParent(self)

        let _ = tabItems.insertTab(tab, at: index)

        return self
    }

    /// Inserts a new tab at the given index and passes it to a callback.
    @discardableResult
    func insertTab<T>(
        _ tab: Destinations,
        at index: Int,
        value: @escaping (T) -> Void
    ) -> Self {
        let t = tab.value(for: self)
        t.coordinatable?.setHasLayerNavigationCoordinatable(self.hasLayerNavigationCoordinatable)
        t.coordinatable?.setParent(self)

        let tab = tabItems.insertTab(t, at: index)

        if tab.coordinatable != nil, let coordinatable = tab.coordinatable as? T {
            value(coordinatable)
        } else if let view = tab.view as? T {
            value(view)
        } else {
            fatalError("Could not cast to type \(T.self)")
        }

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

    /// Returns whether the given destination is currently present in the
    /// tab bar.
    func isInTabItems(_ meta: Destinations.Meta) -> Bool {
        tabItems.tabs.contains(where: { $0.meta as! Self.Destinations.Meta == meta })
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
/// You never create this view directly — call ``Coordinatable/view()``
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
                    .tabItem {
                        if let tabItem = tab.tabItem {
                            AnyView(tabItem)
                        }
                    }
                    .tag(tab.id)
            }
        }
    }

    public var body: some View {
        _coordinator.customize(
            AnyView(
                flowCoordinatableView()
            )
        )
        .environmentCoordinatable(coordinator)
        .id(_coordinator.anyTabItems.id)
    }
}
