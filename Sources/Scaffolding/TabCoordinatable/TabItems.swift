//
//  TabItems.swift
//  Scaffolding
//
//  Created by Alexandr Valíček on 26.09.2025.
//

import SwiftUI
import Observation

/// A type-erased protocol for ``TabItems`` that allows the framework to
/// manipulate tab state without knowing the concrete coordinator type.
@MainActor
public protocol AnyTabItems: AnyObject, CoordinatableData where Coordinator: TabCoordinatable {
    /// The resolved tab destinations.
    var tabs: [Destination] { get set }
    /// The identifier of the currently selected tab.
    var selectedTab: UUID? { get set }
    /// The visibility of the tab bar.
    var tabBarVisibility: Visibility { get set }
    /// The presentation type if this tab coordinator was presented modally.
    var presentedAs: PresentationType? { get set }
}

/// Observable state container for a ``TabCoordinatable`` coordinator.
///
/// `TabItems` holds the array of tab destinations and tracks which tab
/// is selected. It is generic over the coordinator type so that
/// destination enums remain type-safe.
///
/// ```swift
/// var tabItems = TabItems<MainTabCoordinator>(
///     tabs: [.home, .profile, .settings]
/// )
/// ```
@MainActor
@Observable
public class TabItems<Coordinator: TabCoordinatable>: AnyTabItems {
    /// The parent coordinator that owns this tab coordinator, if any.
    public weak var parent: (any Coordinatable)?
    /// Whether a parent flow coordinator provides the navigation layer.
    public var hasLayerNavigationCoordinator: Bool = false
    /// The presentation type when this coordinator was presented modally.
    public var presentedAs: PresentationType?

    /// The resolved tab destinations.
    public var tabs: [Destination] = .init()
    /// The identifier of the currently selected tab.
    public var selectedTab: UUID? = nil

    /// The visibility of the tab bar.
    public var tabBarVisibility: Visibility = .automatic
    /// Whether ``setup(for:)`` has been called.
    public var isSetup: Bool = false
    private var initialTabs: [Coordinator.Destinations] = .init()

    private var pendingSelectionIndex: Int? = nil
    private var pendingSelectionId: UUID? = nil
    private var pendingSelectionFirstMeta: Coordinator.Destinations.Meta? = nil
    private var pendingSelectionLastMeta: Coordinator.Destinations.Meta? = nil

    /// Creates a new tab items container.
    ///
    /// - Parameters:
    ///   - tabs: The destination cases to display as tabs.
    ///   - selectedIndex: An optional zero-based index of the initially
    ///     selected tab.
    ///   - visibility: The initial tab bar visibility.
    public init(
        tabs: [Coordinator.Destinations],
        selectedIndex: Int? = nil,
        visibility: Visibility = .automatic
    ) {
        self.initialTabs = tabs
        self.pendingSelectionIndex = selectedIndex
        self.tabBarVisibility = visibility
    }

    /// Performs one-time setup, resolving initial tab destinations.
    ///
    /// - Parameter coordinator: The coordinator that owns this container.
    public func setup(for coordinator: Coordinator) {
        guard !isSetup else { return }
        self.tabs = initialTabs.map {
            var t = $0.value(for: coordinator)
            t.coordinatable?.setHasLayerNavigationCoordinatable(coordinator.hasLayerNavigationCoordinatable)
            t.coordinatable?.setParent(coordinator)

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

        self.isSetup = true
    }

    /// Sets the parent coordinator reference.
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
            selectedTab = foundTab.id
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
            selectedTab = foundTab.id
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
        selectedTab = selectedDestination.id
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
            selectedTab = foundTab.id
            return foundTab
        }
        return nil
    }

    func setTabs(_ tabs: [Destination]) {
        self.tabs = tabs.map { tab in
            var mutableTab = tab
            if let presentedAs = presentedAs, mutableTab.pushType == nil {
                mutableTab.setPushType(presentedAs)
                propagateDestinationType(to: mutableTab.coordinatable, as: presentedAs)
            }
            return mutableTab
        }

        if let selectedTab = selectedTab,
           !self.tabs.contains(where: { $0.id == selectedTab }) {
            self.selectedTab = self.tabs.first?.id
        }
    }

    func appendTab(_ tab: Destination) -> Destination {
        var mutableTab = tab
        if let presentedAs = presentedAs, mutableTab.pushType == nil {
            mutableTab.setPushType(presentedAs)
            propagateDestinationType(to: mutableTab.coordinatable, as: presentedAs)
        }

        tabs.append(mutableTab)

        if selectedTab == nil {
            selectedTab = mutableTab.id
        }

        return mutableTab
    }

    func insertTab(_ tab: Destination, at index: Int) -> Destination {
        var mutableTab = tab
        if let presentedAs = presentedAs, mutableTab.pushType == nil {
            mutableTab.setPushType(presentedAs)
            propagateDestinationType(to: mutableTab.coordinatable, as: presentedAs)
        }

        let clampedIndex = max(0, min(index, tabs.count))
        tabs.insert(mutableTab, at: clampedIndex)

        if selectedTab == nil {
            selectedTab = mutableTab.id
        }

        return mutableTab
    }

    func removeFirstTab(_ meta: Coordinator.Destinations.Meta) {
        guard let index = tabs.firstIndex(where: { destination in
            guard let destinationMeta = destination.meta as? Coordinator.Destinations.Meta else { return false }
            return destinationMeta == meta
        }) else { return }

        let removedTab = tabs.remove(at: index)

        if selectedTab == removedTab.id {
            if !tabs.isEmpty {
                let newIndex = min(index, tabs.count - 1)
                selectedTab = tabs[newIndex].id
            } else {
                selectedTab = nil
            }
        }
    }

    func removeLastTab(_ meta: Coordinator.Destinations.Meta) {
        guard let index = tabs.lastIndex(where: { destination in
            guard let destinationMeta = destination.meta as? Coordinator.Destinations.Meta else { return false }
            return destinationMeta == meta
        }) else { return }

        let removedTab = tabs.remove(at: index)

        if selectedTab == removedTab.id {
            if !tabs.isEmpty {
                let newIndex = min(index, tabs.count - 1)
                selectedTab = tabs[newIndex].id
            } else {
                selectedTab = nil
            }
        }
    }
}
