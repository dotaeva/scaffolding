//
//  FlowCoordinatable.swift
//  Scaffolding
//
//  Created by Alexandr Valíček on 22.09.2025.
//

import SwiftUI
import Observation
import os.log

/// A coordinator that manages push/pop navigation with a
/// `NavigationStack`.
///
/// Conform to `FlowCoordinatable` to build stack-based navigation flows.
/// Provide a ``FlowStack`` property and define route functions — the
/// ``Scaffoldable(injectsCoordinator:)`` macro generates the `Destinations` enum for you.
///
/// ```swift
/// @Scaffoldable @Observable
/// final class HomeCoordinator: @MainActor FlowCoordinatable {
///     var stack = FlowStack<HomeCoordinator>(root: .home)
///
///     func home() -> some View { HomeView() }
///     func detail(item: String) -> some View { DetailView(item: item) }
/// }
/// ```
///
/// Navigate with ``route(to:onDismiss:)``,
/// ``FlowCoordinatable/present(_:as:onDismiss:)``, and ``pop()``.
@MainActor
public protocol FlowCoordinatable: Coordinatable where ViewType == FlowCoordinatableView {
    /// The observable navigation stack that holds this coordinator's state.
    var stack: FlowStack<Self> { get }

    /// A type-erased accessor for the navigation stack.
    var anyStack: any AnyFlowStack { get }
}

@MainActor
public extension FlowCoordinatable {
    var _dataId: ObjectIdentifier {
        stack.id
    }

    var anyStack: any AnyFlowStack {
        stack.setup(for: self)
        return stack
    }

    var view: FlowCoordinatableView {
        stack.setup(for: self)
        return .init(coordinator: self)
    }

    var parent: (any Coordinatable)? {
        stack.parent
    }

    var hasLayerNavigationCoordinatable: Bool {
        stack.hasLayerNavigationCoordinator
    }

    func setHasLayerNavigationCoordinatable(_ value: Bool) {
        stack.hasLayerNavigationCoordinator = value
    }

    func setParent(_ parent: any Coordinatable) {
        stack.setParent(parent)
    }

    /// Sets the default animation used for root transitions.
    func setRootTransitionAnimation(_ animation: Animation?) {
        stack.setAnimation(animation: animation)
    }
}

@MainActor
extension FlowCoordinatable {
    func bindingStack(for presentationType: PresentationType) -> Binding<[Destination]> {
        guard presentationType == .push else {
            return .constant([])
        }

        return .init {
            self.flattenDestinations(for: presentationType)
        } set: { newValue in
            self.reconstructDestinations(from: newValue, for: presentationType)
        }
    }
}

@MainActor
extension FlowCoordinatable {
    func modalDestinations(for presentationType: PresentationType) -> [Destination] {
        guard presentationType == .sheet || presentationType == .fullScreenCover else {
            return []
        }

        var flattened: [Destination] = []

        if let rootDest = self.anyStack.root {
            traverseCoordinatable(rootDest.coordinatable) { nestedFlow in
                flattened.append(contentsOf: nestedFlow.modalDestinations(for: presentationType))
            }
        }

        for destination in self.anyStack.destinations {
            if destination.pushType == presentationType {
                flattened.append(destination)
            }

            if destination.pushType == .push {
                traverseCoordinatable(destination.coordinatable) { nestedFlow in
                    flattened.append(contentsOf: nestedFlow.modalDestinations(for: presentationType))
                }
            }
        }

        return flattened
    }

    func removeModalDestination(withId id: UUID, type: PresentationType) {
        if let rootDest = self.anyStack.root {
            traverseCoordinatable(rootDest.coordinatable) { nestedFlow in
                nestedFlow.removeModalDestination(withId: id, type: type)
            }
        }

        let toRemove = anyStack.destinations.filter { $0.id == id && $0.pushType == type }
        anyStack.destinations.removeAll { $0.id == id && $0.pushType == type }
        for destination in toRemove {
            destination.resolveDismissal()
        }

        for destination in anyStack.destinations where destination.pushType == .push {
            traverseCoordinatable(destination.coordinatable) { nestedFlow in
                nestedFlow.removeModalDestination(withId: id, type: type)
            }
        }
    }
}

@MainActor
private extension FlowCoordinatable {
    private func flattenDestinations(for presentationType: PresentationType) -> [Destination] {
        var flattened: [Destination] = []

        func flattenRecursively(_ destinations: [Destination]) {
            for destination in destinations {
                guard destination.pushType != .sheet && destination.pushType != .fullScreenCover else {
                    continue
                }

                if destination.pushType == presentationType {
                    flattened.append(destination)
                }

                if destination.pushType == .push {
                    traverseCoordinatable(destination.coordinatable) { nestedFlow in
                        if let rootDest = nestedFlow.anyStack.root {
                            traverseRoots(rootDest.coordinatable)
                        }
                        flattenRecursively(nestedFlow.anyStack.destinations)
                    }
                }
            }
        }

        func traverseRoots(_ coordinatable: (any Coordinatable)?) {
            guard let coordinatable = coordinatable else {
                return
            }

            if let flowCoordinator = coordinatable as? any FlowCoordinatable {
                if flowCoordinator.hasLayerNavigationCoordinatable {
                    if let rootDest = flowCoordinator.anyStack.root {
                        traverseRoots(rootDest.coordinatable)
                    }

                    flattenRecursively(flowCoordinator.anyStack.destinations)
                }
            } else if let tabCoordinator = coordinatable as? any TabCoordinatable {
                if let selectedTabId = tabCoordinator.anyTabItems.selectedTab,
                   let selectedTab = tabCoordinator.anyTabItems.tabs.first(where: { $0.id == selectedTabId }) {
                    traverseRoots(selectedTab.coordinatable)
                }
            } else if let rootCoordinator = coordinatable as? any RootCoordinatable,
                      let rootDestination = rootCoordinator.anyRoot.root {
                traverseRoots(rootDestination.coordinatable)
            }
        }

        if let rootDest = self.anyStack.root {
            traverseRoots(rootDest.coordinatable)
        }

        flattenRecursively(self.anyStack.destinations)

        return flattened
    }

    private func reconstructDestinations(from flattenedDestinations: [Destination], for presentationType: PresentationType) {
        var flatIndex = 0

        func reconstructRecursively(for coordinator: any FlowCoordinatable) -> [Destination] {
            var newDestinations: [Destination] = []

            for originalDestination in coordinator.anyStack.destinations {
                if originalDestination.pushType == .sheet || originalDestination.pushType == .fullScreenCover {
                    newDestinations.append(originalDestination)
                    continue
                }

                if originalDestination.pushType == presentationType {
                    if flatIndex < flattenedDestinations.count {
                        let flatDest = flattenedDestinations[flatIndex]

                        if flatDest.id == originalDestination.id {
                            newDestinations.append(flatDest)
                            flatIndex += 1

                            if originalDestination.pushType == .push {
                                traverseCoordinatable(originalDestination.coordinatable) { nestedFlow in
                                    if let rootDest = nestedFlow.anyStack.root {
                                        traverseAndReconstructRoots(rootDest.coordinatable)
                                    }
                                    let reconstructedNested = reconstructRecursively(for: nestedFlow)
                                    nestedFlow.anyStack.destinations = reconstructedNested
                                }
                            }
                        }
                    }
                } else {
                    newDestinations.append(originalDestination)
                }
            }

            return newDestinations
        }

        func traverseAndReconstructRoots(_ coordinatable: (any Coordinatable)?) {
            guard let coordinatable = coordinatable else {
                return
            }

            if let flowCoordinator = coordinatable as? any FlowCoordinatable {
                if flowCoordinator.hasLayerNavigationCoordinatable {
                    if let rootDest = flowCoordinator.anyStack.root {
                        traverseAndReconstructRoots(rootDest.coordinatable)
                    }

                    if flatIndex < flattenedDestinations.count || !flowCoordinator.anyStack.destinations.isEmpty {
                        let reconstructed = reconstructRecursively(for: flowCoordinator)
                        flowCoordinator.anyStack.destinations = reconstructed
                    } else {
                        flowCoordinator.anyStack.destinations = []
                    }
                }
            } else if let tabCoordinator = coordinatable as? any TabCoordinatable {
                if let selectedTabId = tabCoordinator.anyTabItems.selectedTab,
                   let selectedTab = tabCoordinator.anyTabItems.tabs.first(where: { $0.id == selectedTabId }) {
                    traverseAndReconstructRoots(selectedTab.coordinatable)
                }
            } else if let rootCoordinator = coordinatable as? any RootCoordinatable,
                      let rootDestination = rootCoordinator.anyRoot.root {
                traverseAndReconstructRoots(rootDestination.coordinatable)
            }
        }

        if let rootDest = self.anyStack.root {
            traverseAndReconstructRoots(rootDest.coordinatable)
        }

        let reconstructed = reconstructRecursively(for: self)
        self.anyStack.destinations = reconstructed
    }
}

@MainActor
private extension FlowCoordinatable {
    func traverseCoordinatable(_ coordinatable: (any Coordinatable)?, action: (any FlowCoordinatable) -> Void) {
        guard let coordinatable = coordinatable else { return }

        if let flowCoordinator = coordinatable as? any FlowCoordinatable {
            action(flowCoordinator)
        } else if let tabCoordinator = coordinatable as? any TabCoordinatable {
            if let selectedTabId = tabCoordinator.anyTabItems.selectedTab,
               let selectedTab = tabCoordinator.anyTabItems.tabs.first(where: { $0.id == selectedTabId }),
               let nestedFlow = selectedTab.coordinatable as? any FlowCoordinatable {
                action(nestedFlow)
            }
        } else if let rootCoordinator = coordinatable as? any RootCoordinatable,
                  let rootDestination = rootCoordinator.anyRoot.root {
            traverseCoordinatable(rootDestination.coordinatable, action: action)
        }
    }

    func checkForMultipleModals(pushType: PresentationType) {
        func findLayerFlowParent(lookup: (any Coordinatable)?) -> any FlowCoordinatable {
            if let flowCoordinatable = lookup as? (any FlowCoordinatable) {
                if !flowCoordinatable.anyStack.hasLayerNavigationCoordinator {
                    return flowCoordinatable
                }
                return findLayerFlowParent(lookup: flowCoordinatable.anyStack.parent)
            }
            return self
        }

        let existingModals = findLayerFlowParent(lookup: self).modalDestinations(for: pushType)

        if existingModals.count > 1 {
            let logger = Logger(subsystem: "Scaffolding", category: "Modal")
            logger.critical("Scaffolding: Currently, only presenting a single sheet is supported.\nThe next sheet will be presented when the currently presented sheet gets dismissed.")
        }
    }
}

@MainActor
public extension FlowCoordinatable {
    /// Replaces the root destination of this flow coordinator.
    ///
    /// - Parameters:
    ///   - destination: The new root destination.
    ///   - animation: An optional animation override. When `nil` the
    ///     stack's default animation is used.
    /// - Returns: `self` for chaining.
    @discardableResult
    func setRoot(_ destination: Destinations, animation: Animation? = nil) -> Self {
        let dest = destination.value(for: self)
        dest.coordinatable?.setParent(self)
        stack.setRoot(root: dest, animation: animation)
        return self
    }

    /// Pushes a destination onto the navigation stack.
    ///
    /// `route(to:)` is a push-only operation — to present a destination
    /// modally, use ``FlowCoordinatable/present(_:as:onDismiss:)`` instead.
    ///
    /// - Parameters:
    ///   - destination: The destination to push.
    ///   - onDismiss: A closure invoked when the pushed destination is
    ///     popped or otherwise removed from the stack.
    /// - Returns: `self` for chaining.
    @discardableResult
    func route(
        to destination: Destinations,
        onDismiss: @escaping @MainActor () -> Void = { }
    ) -> Self {
        performRoute(to: destination, as: .push, onDismiss: onDismiss)
        return self
    }

    /// Presents a destination modally on this flow coordinator.
    ///
    /// The modal lives on this coordinator's stack and is rendered as a
    /// sheet or full-screen cover by the flow's view layer.
    ///
    /// - Parameters:
    ///   - destination: The destination to present.
    ///   - type: The modal presentation style. Defaults to `.sheet`.
    ///   - onDismiss: A closure invoked when the modal is dismissed.
    /// - Returns: `self` for chaining.
    @discardableResult
    func present(
        _ destination: Destinations,
        as type: ModalPresentationType = .sheet,
        onDismiss: @escaping @MainActor () -> Void = { }
    ) -> Self {
        performRoute(to: destination, as: type.presentationType, onDismiss: onDismiss)
        return self
    }

    /// Pops the top destination from the navigation stack.
    ///
    /// If the stack is empty the coordinator dismisses itself from its
    /// parent instead.
    ///
    /// - Returns: `self` for chaining.
    @discardableResult
    func pop() -> Self {
        stack.pop()
        return self
    }

    /// Pops all pushed destinations, returning to the root.
    ///
    /// - Returns: `self` for chaining.
    @discardableResult
    func popToRoot() -> Self {
        stack.popToRoot()
        return self
    }

    /// Pops the stack back to the **first** occurrence of the given
    /// destination.
    ///
    /// - Parameter destination: The destination meta to search for.
    /// - Returns: `self` for chaining.
    @discardableResult
    func popToFirst(_ destination: Destinations.Meta) -> Self {
        _ = stack.popToFirst(destination)
        return self
    }

    /// Pops the stack back to the **last** occurrence of the given
    /// destination.
    ///
    /// - Parameter destination: The destination meta to search for.
    /// - Returns: `self` for chaining.
    @discardableResult
    func popToLast(_ destination: Destinations.Meta) -> Self {
        _ = stack.popToLast(destination)
        return self
    }

    /// Returns whether the given destination is currently in the
    /// navigation stack.
    func isInStack(_ destination: Destinations.Meta) -> Bool {
        stack.destinations.contains { dest in
            guard let destMeta = dest.meta as? Self.Destinations.Meta else { return false }
            return destMeta == destination
        }
    }
}

@MainActor
public extension FlowCoordinatable {
    /// Pushes a destination and invokes a typed callback with the resolved
    /// child coordinator.
    ///
    /// The callback fires once after the destination is pushed, receiving
    /// the newly created coordinator cast to `T`. If the destination does
    /// not resolve to a coordinator of type `T`, the callback is not
    /// invoked.
    @discardableResult
    func route<T: Coordinatable>(
        to destination: Destinations,
        onDismiss: @escaping @MainActor () -> Void = { },
        _ action: @escaping @MainActor (T) -> Void
    ) -> Self {
        let dest = performRoute(to: destination, as: .push, onDismiss: onDismiss)
        if let coordinator = dest.coordinatable as? T {
            action(coordinator)
        }
        return self
    }

    /// Presents a destination modally and invokes a typed callback with the
    /// resolved child coordinator.
    ///
    /// The callback fires once after the modal lands on the stack, receiving
    /// the newly created coordinator cast to `T`. If the destination does
    /// not resolve to a coordinator of type `T`, the callback is not
    /// invoked.
    @discardableResult
    func present<T: Coordinatable>(
        _ destination: Destinations,
        as type: ModalPresentationType = .sheet,
        onDismiss: @escaping @MainActor () -> Void = { },
        _ action: @escaping @MainActor (T) -> Void
    ) -> Self {
        let dest = performRoute(to: destination, as: type.presentationType, onDismiss: onDismiss)
        if let coordinator = dest.coordinatable as? T {
            action(coordinator)
        }
        return self
    }

    /// Replaces the root and invokes a typed callback with the resolved
    /// child coordinator.
    @discardableResult
    func setRoot<T: Coordinatable>(
        _ destination: Destinations,
        animation: Animation? = nil,
        _ action: @escaping @MainActor (T) -> Void
    ) -> Self {
        let dest = destination.value(for: self)
        dest.coordinatable?.setParent(self)
        stack.setRoot(root: dest, animation: animation)
        if let coordinator = dest.coordinatable as? T {
            action(coordinator)
        }
        return self
    }

    /// Pops to the **first** matching destination and invokes a typed
    /// callback with the destination's coordinator, if any.
    @discardableResult
    func popToFirst<T: Coordinatable>(
        _ destination: Destinations.Meta,
        _ action: @escaping @MainActor (T) -> Void
    ) -> Self {
        if let dest = stack.popToFirst(destination),
           let coordinator = dest.coordinatable as? T {
            action(coordinator)
        }
        return self
    }

    /// Pops to the **last** matching destination and invokes a typed
    /// callback with the destination's coordinator, if any.
    @discardableResult
    func popToLast<T: Coordinatable>(
        _ destination: Destinations.Meta,
        _ action: @escaping @MainActor (T) -> Void
    ) -> Self {
        if let dest = stack.popToLast(destination),
           let coordinator = dest.coordinatable as? T {
            action(coordinator)
        }
        return self
    }
}

@MainActor
private extension FlowCoordinatable {
    @discardableResult
    func performRoute(
        to destination: Destinations,
        as pushType: PresentationType,
        onDismiss: @escaping @MainActor () -> Void
    ) -> Destination {
        var dest = destination.value(for: self)

        dest.setOnDismiss(onDismiss)
        dest.setPushType(pushType)
        dest.setRouteType(DestinationType.from(presentationType: pushType))
        dest.coordinatable?.setHasLayerNavigationCoordinatable(pushType == .push)
        dest.coordinatable?.setParent(self)

        if let flowCoordinator = dest.coordinatable as? any FlowCoordinatable {
            flowCoordinator.setPresentedAs(pushType)
        }

        stack.push(destination: dest)

        checkForMultipleModals(pushType: pushType)
        return dest
    }
}

@MainActor
extension FlowCoordinatable {
    func setPresentedAs(_ type: PresentationType) {
        stack.presentedAs = type
        if var root = stack.root, root.pushType == nil {
            root.setPushType(type)
            stack.root = root
        }
    }
}

/// The SwiftUI view generated by a ``FlowCoordinatable`` coordinator.
///
/// You never create this view directly — access ``Coordinatable/view``
/// on a `FlowCoordinatable` coordinator to obtain it.
public struct FlowCoordinatableView: CoordinatableView {
    private let _coordinator: any FlowCoordinatable

    public var coordinator: any Coordinatable {
        _coordinator
    }

    init(coordinator: any FlowCoordinatable) {
        self._coordinator = coordinator
    }

    @ViewBuilder
    private func coordinatorView() -> some View {
        if let rootView = _coordinator.anyStack.root?.view {
            flowCoordinatableView(view: AnyView(rootView))
        } else if let c = _coordinator.anyStack.root?.coordinatable {
            flowCoordinatableView(view: AnyView(c.view))
        } else {
            EmptyView()
        }
    }

    private func flowCoordinatableView(view: AnyView) -> some View {
        NavigationStack(path: _coordinator.bindingStack(for: .push)) {
            view
                .navigationDestination(for: Destination.self, destination: wrappedView)
        }
        // Reset the NavigationStack identity when the root changes so that
        // SwiftUI drops any stale internal navigation state (e.g. lingering
        // navigation bar from a previous root's deep push hierarchy).
        .id(_coordinator.anyStack.root?.id)
        .applySheets(from: _coordinator, modalContent: wrappedView)
        .applyFullScreenCovers(from: _coordinator, modalContent: wrappedView)
    }

    public var body: some View {
        _coordinator.customize(
            AnyView(
                Group {
                    if _coordinator.anyStack.hasLayerNavigationCoordinator {
                        if let rootView = _coordinator.anyStack.root?.view {
                            AnyView(rootView)
                        } else if let c = _coordinator.anyStack.root?.coordinatable {
                            AnyView(c.view)
                                .environmentCoordinatable(c)
                        } else {
                            EmptyView()
                        }
                    } else {
                        coordinatorView()
                    }
                }
            )
        )
        .environmentCoordinatable(_coordinator)
        .id(_coordinator.anyStack.id)
    }
}
