//
//  TabItems.swift
//  Scaffolding
//
//  Created by Alexandr Valíček on 26.09.2025.
//

import SwiftUI
import Observation

/// A read-only, type-erased view of a ``TabItems`` container.
///
/// Change tabs and selection through the owning ``TabCoordinatable``.
@MainActor
public protocol AnyTabItems: AnyObject, CoordinatableData where Coordinator: TabCoordinatable {
    /// The tab destinations, in display order.
    var tabs: [Destination] { get }
    /// The identifier of the selected tab, or `nil` before the tabs resolve or when there are none.
    var selectedTab: UUID? { get }
    /// The native tab bar's visibility.
    var tabBarVisibility: Visibility { get }
    /// The presentation style inherited from the parent, or `nil`.
    var presentedAs: PresentationType? { get }
    /// This coordinator's modal requests, visible and queued.
    var modals: [Destination] { get }
}

/// The observable state of a ``TabCoordinatable``: its tabs, selection, bar
/// visibility, and modal requests.
///
/// Declare it as a `var` and seed it through the initializer. Change it through
/// the coordinator's methods; never replace a live container.
///
/// ```swift
/// var tabItems = TabItems<MainTabCoordinator>(
///     tabs: [.home, .profile, .settings],
///     selectedIndex: 1
/// )
/// ```
///
/// The initial tabs resolve on first use: rendering, navigation, or a query.
@MainActor
@Observable
public class TabItems<Coordinator: TabCoordinatable>: AnyTabItems {
    /// The coordinator that hosts this one, or `nil` at the top level.
    public internal(set) weak var parent: (any Coordinatable)?
    /// Whether an enclosing flow provides the navigation stack.
    public internal(set) var hasLayerNavigationCoordinator: Bool = false
    /// The presentation style inherited from the parent, or `nil`.
    public internal(set) var presentedAs: PresentationType?
    /// This coordinator's modal requests, visible and queued.
    public internal(set) var modals: [Destination] = []

    /// The tab destinations, in display order.
    public internal(set) var tabs: [Destination] = .init()
    /// The identifier of the selected tab, or `nil` before the tabs resolve or when there are none.
    public internal(set) var selectedTab: UUID? = nil

    /// The native tab bar's visibility.
    public internal(set) var tabBarVisibility: Visibility = .automatic
    /// The default animation for navigation changes. Set it with ``TabCoordinatable/setTransitionAnimation(_:)``.
    public internal(set) var animation: Animation? = .default

    /// Whether the initial tabs have been resolved.
    public internal(set) var isSetup: Bool = false
    private var initialTabs: [Coordinator.Destinations] = .init()

    private var pendingSelectionIndex: Int? = nil
    private var pendingSelectionId: UUID? = nil
    private var pendingSelectionFirstMeta: Coordinator.Destinations.Meta? = nil
    private var pendingSelectionLastMeta: Coordinator.Destinations.Meta? = nil

    /// Creates the container with its initial tabs.
    ///
    /// - Parameters:
    ///   - tabs: The tab cases, in display order.
    ///   - selectedIndex: The initially selected position. `nil` or an
    ///     out-of-range index selects the first tab.
    ///   - visibility: The native tab bar's initial visibility.
    public init(
        tabs: [Coordinator.Destinations],
        selectedIndex: Int? = nil,
        visibility: Visibility = .automatic
    ) {
        self.initialTabs = tabs
        self.pendingSelectionIndex = selectedIndex
        self.tabBarVisibility = visibility
    }

    /// Resolves the initial tabs and selection.
    ///
    /// Runs once; later calls do nothing. The framework calls this; apps don't
    /// need to.
    ///
    /// - Parameter coordinator: The owning coordinator.
    public func setup(for coordinator: Coordinator) {
        guard !isSetup else { return }
        isSetup = true
        self.tabs = initialTabs.map {
            var t = $0.resolvedValue(for: coordinator)
            t.coordinatable?.attach(to: coordinator, navigationLayer: coordinator.hasLayerNavigationCoordinatable, presentation: presentedAs)

            if let presentedAs = presentedAs {
                t.setPushType(presentedAs)
                propagateDestinationType(to: t.coordinatable, as: presentedAs)
            }

            return t
        }

        if let pendingId = pendingSelectionId,
           let foundTab = tabs.first(where: { $0.id == pendingId }) {
            selectedTab = foundTab.id
        } else if let pendingMeta = pendingSelectionFirstMeta,
                  let foundTab = tabs.first(where: { destination in
                      guard let destinationMeta = destination.meta as? Coordinator.Destinations.Meta else { return false }
                      return destinationMeta == pendingMeta
                  }) {
            selectedTab = foundTab.id
        } else if let pendingMeta = pendingSelectionLastMeta,
                  let foundTab = tabs.last(where: { destination in
                      guard let destinationMeta = destination.meta as? Coordinator.Destinations.Meta else { return false }
                      return destinationMeta == pendingMeta
                  }) {
            selectedTab = foundTab.id
        } else if let pendingIndex = pendingSelectionIndex,
                  pendingIndex >= 0 && pendingIndex < tabs.count {
            selectedTab = tabs[pendingIndex].id
        } else {
            selectedTab = tabs.first?.id
        }

        pendingSelectionIndex = nil
        pendingSelectionId = nil
        pendingSelectionFirstMeta = nil
        pendingSelectionLastMeta = nil
        initialTabs = []
    }

    /// Records the hosting coordinator.
    ///
    /// The framework calls this; apps don't need to.
    public func setParent(_ parent: any Coordinatable) {
        self.parent = parent
    }

    func setTabBarVisibility(_ value: Visibility) {
        self.tabBarVisibility = value
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

extension TabItems {
    func select(first tab: Coordinator.Destinations.Meta) -> Destination? {
        guard isSetup else {
            pendingSelectionFirstMeta = tab
            pendingSelectionLastMeta = nil
            pendingSelectionIndex = nil
            pendingSelectionId = nil
            return nil
        }

        if let foundTab = tabs.first(where: { destination in
            guard let destinationMeta = destination.meta as? Coordinator.Destinations.Meta else { return false }
            return destinationMeta == tab
        }) {
            withScaffoldingAnimation(animation) { selectedTab = foundTab.id }
            return foundTab
        }
        return nil
    }

    func select(last tab: Coordinator.Destinations.Meta) -> Destination? {
        guard isSetup else {
            pendingSelectionLastMeta = tab
            pendingSelectionFirstMeta = nil
            pendingSelectionIndex = nil
            pendingSelectionId = nil
            return nil
        }

        if let foundTab = tabs.last(where: { destination in
            guard let destinationMeta = destination.meta as? Coordinator.Destinations.Meta else { return false }
            return destinationMeta == tab
        }) {
            withScaffoldingAnimation(animation) { selectedTab = foundTab.id }
            return foundTab
        }
        return nil
    }

    func select(_ index: Int) -> Destination? {
        guard isSetup else {
            if index >= 0 && index < initialTabs.count {
                pendingSelectionIndex = index
                pendingSelectionFirstMeta = nil
                pendingSelectionLastMeta = nil
                pendingSelectionId = nil
            }
            return nil
        }

        guard index >= 0 && index < tabs.count else { return nil }
        let selectedDestination = tabs[index]
        withScaffoldingAnimation(animation) { selectedTab = selectedDestination.id }
        return selectedDestination
    }

    func select(_ id: UUID) -> Destination? {
        guard isSetup else {
            pendingSelectionId = id
            pendingSelectionIndex = nil
            pendingSelectionFirstMeta = nil
            pendingSelectionLastMeta = nil
            return nil
        }

        if let foundTab = tabs.first(where: { $0.id == id }) {
            withScaffoldingAnimation(animation) { selectedTab = foundTab.id }
            return foundTab
        }
        return nil
    }

    func setTabs(_ tabs: [Destination]) {
        let removed = self.tabs.filter { old in !tabs.contains { $0.id == old.id } }
        withScaffoldingAnimation(animation) {
            self.tabs = tabs.map { tab in
                var mutableTab = tab
                if let presentedAs = presentedAs, mutableTab.pushType == nil {
                    mutableTab.setPushType(presentedAs)
                    propagateDestinationType(to: mutableTab.coordinatable, as: presentedAs)
                }
                return mutableTab
            }

            if !self.tabs.contains(where: { $0.id == selectedTab }) {
                self.selectedTab = self.tabs.first?.id
            }
        }
        resolveDismissals(removed)
    }

    func appendTab(_ tab: Destination) -> Destination {
        var mutableTab = tab
        if let presentedAs = presentedAs, mutableTab.pushType == nil {
            mutableTab.setPushType(presentedAs)
            propagateDestinationType(to: mutableTab.coordinatable, as: presentedAs)
        }

        withScaffoldingAnimation(animation) {
            tabs.append(mutableTab)

            if selectedTab == nil {
                selectedTab = mutableTab.id
            }
        }

        return mutableTab
    }

    func insertTab(_ tab: Destination, at index: Int) -> Destination {
        var mutableTab = tab
        if let presentedAs = presentedAs, mutableTab.pushType == nil {
            mutableTab.setPushType(presentedAs)
            propagateDestinationType(to: mutableTab.coordinatable, as: presentedAs)
        }

        withScaffoldingAnimation(animation) {
            let clampedIndex = max(0, min(index, tabs.count))
            tabs.insert(mutableTab, at: clampedIndex)

            if selectedTab == nil {
                selectedTab = mutableTab.id
            }
        }

        return mutableTab
    }

    func removeFirstTab(_ meta: Coordinator.Destinations.Meta) {
        guard let index = tabs.firstIndex(where: { destination in
            guard let destinationMeta = destination.meta as? Coordinator.Destinations.Meta else { return false }
            return destinationMeta == meta
        }) else { return }

        let removedTab = withScaffoldingAnimation(animation) {
            let removed = tabs.remove(at: index)
            if selectedTab == removed.id {
                selectedTab = tabs.isEmpty ? nil : tabs[min(index, tabs.count - 1)].id
            }
            return removed
        }
        removedTab.resolveDismissal()
    }

    func setBadge(_ value: String?, forFirst meta: Coordinator.Destinations.Meta) {
        guard let index = tabs.firstIndex(where: { destination in
            guard let destinationMeta = destination.meta as? Coordinator.Destinations.Meta else { return false }
            return destinationMeta == meta
        }) else { return }
        tabs[index].badge = value
    }

    func badge(forFirst meta: Coordinator.Destinations.Meta) -> String? {
        tabs.first(where: { destination in
            guard let destinationMeta = destination.meta as? Coordinator.Destinations.Meta else { return false }
            return destinationMeta == meta
        })?.badge
    }

    func setTabAccessibilityIdentifier(_ identifier: String?, forFirst meta: Coordinator.Destinations.Meta) {
        guard let index = tabs.firstIndex(where: { destination in
            guard let destinationMeta = destination.meta as? Coordinator.Destinations.Meta else { return false }
            return destinationMeta == meta
        }) else { return }
        tabs[index].accessibilityIdentifier = identifier
    }

    func tabAccessibilityIdentifier(forFirst meta: Coordinator.Destinations.Meta) -> String? {
        tabs.first(where: { destination in
            guard let destinationMeta = destination.meta as? Coordinator.Destinations.Meta else { return false }
            return destinationMeta == meta
        })?.accessibilityIdentifier
    }

    func removeLastTab(_ meta: Coordinator.Destinations.Meta) {
        guard let index = tabs.lastIndex(where: { destination in
            guard let destinationMeta = destination.meta as? Coordinator.Destinations.Meta else { return false }
            return destinationMeta == meta
        }) else { return }

        let removedTab = withScaffoldingAnimation(animation) {
            let removed = tabs.remove(at: index)
            if selectedTab == removed.id {
                selectedTab = tabs.isEmpty ? nil : tabs[min(index, tabs.count - 1)].id
            }
            return removed
        }
        removedTab.resolveDismissal()
    }

}

@MainActor
protocol _MutableTabItems: AnyTabItems, _MutableCoordinatableData {
    var animation: Animation? { get set }
    var tabs: [Destination] { get set }
    var selectedTab: UUID? { get set }
    var tabBarVisibility: Visibility { get set }
    var presentedAs: PresentationType? { get set }
    var modals: [Destination] { get set }
}

extension TabItems: _MutableTabItems {}
