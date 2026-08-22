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
/// ``Scaffoldable(injectsCoordinator:codable:)`` macro generates the `Destinations` enum for you.
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
/// Navigate with ``route(to:policy:onDismiss:)``,
/// ``FlowCoordinatable/present(_:as:policy:onDismiss:)``, and ``pop()``.
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

        /// Destinations the incoming path no longer contains.
        ///
        /// SwiftUI writes a shorter path whenever the user navigates back —
        /// the back button, the back swipe, a long-press "pop to root".
        /// Those destinations are just as gone as after a programmatic
        /// `pop()`, so they owe their `onDismiss` and any suspended
        /// `routeAndWait` continuation a resolution. Collected while the
        /// arrays are rebuilt and resolved once at the end, so callbacks
        /// observe a settled hierarchy rather than a half-reconstructed one.
        var dropped: [Destination] = []

        /// A dropped destination takes its subtree with it: the coordinator
        /// it hosts is unreachable now, so anything pushed *inside* that
        /// coordinator must resolve too. Walks only already-materialised
        /// children — tearing a branch down must never build the rest of it.
        func collectDropped(_ destination: Destination) {
            dropped.append(destination)

            guard let child = destination.materializedCoordinatable else { return }
            collectDroppedBelow(child)
        }

        func collectDroppedBelow(_ coordinatable: any Coordinatable) {
            if let flow = coordinatable as? any FlowCoordinatable {
                let nested = flow.anyStack.destinations
                flow.anyStack.destinations = []
                for destination in nested { collectDropped(destination) }
            } else if let tabs = coordinatable as? any TabCoordinatable {
                for tab in tabs.anyTabItems.tabs {
                    guard let child = tab.materializedCoordinatable else { continue }
                    collectDroppedBelow(child)
                }
            } else if let root = coordinatable as? any RootCoordinatable,
                      let child = root.anyRoot.root?.materializedCoordinatable {
                collectDroppedBelow(child)
            }
        }

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
                        } else {
                            collectDropped(originalDestination)
                        }
                    } else {
                        collectDropped(originalDestination)
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

        // Topmost first, matching the order the programmatic pop family
        // resolves in. `resolveDismissal()` is single-shot, so a
        // destination already resolved by a `pop()` that SwiftUI is only
        // now catching up with is a no-op here.
        for destination in dropped.reversed() {
            destination.resolveDismissal()
        }
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
        let dest = destination.resolvedValue(for: self)
        dest.coordinatable?.setParent(self)
        stack.setRoot(root: dest, animation: animation)
        return self
    }

    /// Pushes a destination onto the navigation stack.
    ///
    /// `route(to:)` is a push-only operation — to present a destination
    /// modally, use ``FlowCoordinatable/present(_:as:policy:onDismiss:)`` instead.
    ///
    /// The `onDismiss` closure has an `async` alternative: to continue
    /// straight after the pushed destination is popped, `await`
    /// ``FlowCoordinatable/routeAndWait(to:policy:)`` instead of passing a
    /// callback.
    ///
    /// - Parameters:
    ///   - destination: The destination to push.
    ///   - policy: Pass ``RoutePolicy/distinct`` to skip the push when the
    ///     same destination case is already on top — a guard against
    ///     double-taps. Defaults to ``RoutePolicy/always``.
    ///   - onDismiss: A closure invoked when the pushed destination is
    ///     popped or otherwise removed from the stack.
    /// - Returns: `self` for chaining.
    @discardableResult
    func route(
        to destination: Destinations,
        policy: RoutePolicy = .always,
        onDismiss: @escaping @MainActor () -> Void = { }
    ) -> Self {
        guard !policySkips(destination, policy: policy, as: .push) else { return self }
        performRoute(to: destination, as: .push, onDismiss: onDismiss)
        return self
    }

    /// Presents a destination modally on this flow coordinator.
    ///
    /// The modal lives on this coordinator's stack and is rendered as a
    /// sheet or full-screen cover by the flow's view layer.
    ///
    /// The `onDismiss` closure has `async` alternatives: `await`
    /// ``FlowCoordinatable/presentAndWait(_:as:policy:)`` to continue once the
    /// modal closes, or ``FlowCoordinatable/present(_:as:policy:awaiting:)``
    /// to take a value back from it.
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
        guard !policySkips(destination, policy: policy, as: type.presentationType) else { return self }
        performRoute(
            to: destination,
            as: type.presentationType,
            configuration: type.configuration,
            onDismiss: onDismiss
        )
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

    /// The number of destinations pushed above the root.
    ///
    /// Modally presented destinations are not counted — this is the depth
    /// of the push stack. `0` means the flow is at its root.
    var depth: Int {
        stack.destinations.count { $0.pushType == .push }
    }

    /// The destination case currently on top of the push stack.
    ///
    /// Returns the meta of the topmost *pushed* destination, or the root's
    /// meta when nothing is pushed. Modals are ignored.
    var topDestination: Destinations.Meta? {
        if let last = stack.destinations.last(where: { $0.pushType == .push }) {
            return last.meta as? Destinations.Meta
        }
        return anyStack.root?.meta as? Destinations.Meta
    }

    /// Whether this coordinator currently presents a modal (sheet or
    /// full-screen cover) on its own stack.
    var isPresentingModal: Bool {
        stack.destinations.contains {
            $0.pushType == .sheet || $0.pushType == .fullScreenCover
        }
    }

    /// The number of occurrences of the given destination case in the
    /// navigation stack (pushed and presented destinations; the root is
    /// not counted).
    func count(of destination: Destinations.Meta) -> Int {
        stack.destinations.count { dest in
            guard let destMeta = dest.meta as? Self.Destinations.Meta else { return false }
            return destMeta == destination
        }
    }

    /// Pops up to `count` destinations from the navigation stack.
    ///
    /// Unlike repeated calls to ``pop()``, this stops at the root — it
    /// never dismisses the coordinator itself when the stack runs out.
    ///
    /// - Parameter count: The number of destinations to remove.
    /// - Returns: `self` for chaining.
    @discardableResult
    func pop(_ count: Int) -> Self {
        stack.pop(count: count)
        return self
    }

    /// Replaces the topmost pushed destination with a new one.
    ///
    /// The replaced destination's `onDismiss` fires exactly once. Use this
    /// for transitions where back should skip the current screen — e.g.
    /// replacing a loading screen with its result, or advancing a wizard
    /// step without letting the user return to it.
    ///
    /// When nothing is pushed the destination is pushed normally, like
    /// ``route(to:policy:onDismiss:)`` — the root is never replaced (use
    /// ``setRoot(_:animation:)`` for that).
    ///
    /// - Parameters:
    ///   - destination: The destination that takes the top position.
    ///   - onDismiss: A closure invoked when the new destination is
    ///     popped or otherwise removed from the stack.
    /// - Returns: `self` for chaining.
    @discardableResult
    func replaceLast(
        with destination: Destinations,
        onDismiss: @escaping @MainActor () -> Void = { }
    ) -> Self {
        guard let index = stack.destinations.lastIndex(where: { $0.pushType == .push }) else {
            return route(to: destination, onDismiss: onDismiss)
        }

        let dest = makeDestination(for: destination, as: .push, onDismiss: onDismiss)
        let replaced = stack.destinations[index]
        stack.destinations[index] = dest
        replaced.resolveDismissal()
        return self
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
        policy: RoutePolicy = .always,
        onDismiss: @escaping @MainActor () -> Void = { },
        _ action: @escaping @MainActor (T) -> Void
    ) -> Self {
        guard !policySkips(destination, policy: policy, as: .push) else { return self }
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
        policy: RoutePolicy = .always,
        onDismiss: @escaping @MainActor () -> Void = { },
        _ action: @escaping @MainActor (T) -> Void
    ) -> Self {
        guard !policySkips(destination, policy: policy, as: type.presentationType) else { return self }
        let dest = performRoute(
            to: destination,
            as: type.presentationType,
            configuration: type.configuration,
            onDismiss: onDismiss
        )
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
        let dest = destination.resolvedValue(for: self)
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
extension FlowCoordinatable {
    func makeDestination(
        for destination: Destinations,
        as pushType: PresentationType,
        configuration: SheetConfiguration? = nil,
        onDismiss: @escaping @MainActor () -> Void
    ) -> Destination {
        var dest = destination.resolvedValue(for: self)

        dest.setOnDismiss(onDismiss)
        dest.setPushType(pushType)
        dest.setRouteType(DestinationType.from(presentationType: pushType))
        dest.setModalConfiguration(configuration)
        if pushType == .push {
            // Modal presentation from a flow is fine — the sheet/cover is
            // its own navigation context. Pushing a split view is not.
            _warnIfSplitInsideNavigationStack(dest.coordinatable)
        }
        dest.coordinatable?.setHasLayerNavigationCoordinatable(pushType == .push)
        dest.coordinatable?.setParent(self)

        if let flowCoordinator = dest.coordinatable as? any FlowCoordinatable {
            flowCoordinator.setPresentedAs(pushType)
        }

        return dest
    }

    @discardableResult
    func performRoute(
        to destination: Destinations,
        as pushType: PresentationType,
        configuration: SheetConfiguration? = nil,
        onDismiss: @escaping @MainActor () -> Void
    ) -> Destination {
        let dest = makeDestination(
            for: destination,
            as: pushType,
            configuration: configuration,
            onDismiss: onDismiss
        )

        stack.push(destination: dest)

        checkForMultipleModals(pushType: pushType)
        return dest
    }

    /// Whether a `.distinct` policy should skip this navigation request.
    func policySkips(
        _ destination: Destinations,
        policy: RoutePolicy,
        as pushType: PresentationType
    ) -> Bool {
        guard case .distinct = policy else { return false }

        if pushType == .push {
            return topDestination == destination.meta
        }

        return stack.destinations.contains { dest in
            guard dest.pushType == .sheet || dest.pushType == .fullScreenCover else { return false }
            guard let destMeta = dest.meta as? Destinations.Meta else { return false }
            return destMeta == destination.meta
        }
    }
}

// MARK: - Typed child resolution

@MainActor
public extension FlowCoordinatable {
    /// Pushes a destination and returns its resolved child coordinator.
    ///
    /// A non-closure alternative to
    /// ``route(to:policy:onDismiss:_:)`` that flattens deep-link chains:
    ///
    /// ```swift
    /// let settings = route(to: .settings, expecting: SettingsCoordinator.self)
    /// settings?.route(to: .account)
    /// ```
    ///
    /// - Returns: The child coordinator cast to `T`, or `nil` when the
    ///   destination is view-only, resolves to a different type, or the
    ///   policy skipped the push.
    func route<T: Coordinatable>(
        to destination: Destinations,
        policy: RoutePolicy = .always,
        onDismiss: @escaping @MainActor () -> Void = { },
        expecting coordinatorType: T.Type
    ) -> T? {
        guard !policySkips(destination, policy: policy, as: .push) else { return nil }
        let dest = performRoute(to: destination, as: .push, onDismiss: onDismiss)
        return dest.coordinatable as? T
    }

    /// Presents a destination modally and returns its resolved child
    /// coordinator. See ``route(to:policy:onDismiss:expecting:)``.
    func present<T: Coordinatable>(
        _ destination: Destinations,
        as type: ModalPresentationType = .sheet,
        policy: RoutePolicy = .always,
        onDismiss: @escaping @MainActor () -> Void = { },
        expecting coordinatorType: T.Type
    ) -> T? {
        guard !policySkips(destination, policy: policy, as: type.presentationType) else { return nil }
        let dest = performRoute(
            to: destination,
            as: type.presentationType,
            configuration: type.configuration,
            onDismiss: onDismiss
        )
        return dest.coordinatable as? T
    }

    /// Replaces the root and returns its resolved child coordinator.
    /// See ``route(to:policy:onDismiss:expecting:)``.
    func setRoot<T: Coordinatable>(
        _ destination: Destinations,
        animation: Animation? = nil,
        expecting coordinatorType: T.Type
    ) -> T? {
        let dest = destination.resolvedValue(for: self)
        dest.coordinatable?.setParent(self)
        stack.setRoot(root: dest, animation: animation)
        return dest.coordinatable as? T
    }

    /// Pops to the **first** matching destination and returns its child
    /// coordinator, if any.
    func popToFirst<T: Coordinatable>(
        _ destination: Destinations.Meta,
        expecting coordinatorType: T.Type
    ) -> T? {
        stack.popToFirst(destination)?.coordinatable as? T
    }

    /// Pops to the **last** matching destination and returns its child
    /// coordinator, if any.
    func popToLast<T: Coordinatable>(
        _ destination: Destinations.Meta,
        expecting coordinatorType: T.Type
    ) -> T? {
        stack.popToLast(destination)?.coordinatable as? T
    }
}

// MARK: - Awaitable navigation

@MainActor
public extension FlowCoordinatable {
    /// Pushes a destination and suspends until it is popped or otherwise
    /// removed from the stack.
    ///
    /// The suspension resumes exactly once, no matter how the destination
    /// leaves the stack — `pop()`, `popToRoot()`, a back swipe, a root
    /// swap, or the whole coordinator being dismissed.
    ///
    /// ```swift
    /// await routeAndWait(to: .picker)
    /// // picker was closed — read whatever state it wrote
    /// ```
    ///
    /// - Parameters:
    ///   - destination: The destination to push.
    ///   - policy: See ``route(to:policy:onDismiss:)``. When the policy
    ///     skips the push, this returns immediately.
    func routeAndWait(
        to destination: Destinations,
        policy: RoutePolicy = .always
    ) async {
        guard !policySkips(destination, policy: policy, as: .push) else { return }
        let dest = performRoute(to: destination, as: .push, onDismiss: { })
        await dest.resolution.awaitResolution()
    }

    /// Presents a destination modally and suspends until it is dismissed.
    ///
    /// The suspension resumes exactly once, whether the modal is dismissed
    /// interactively, via ``Coordinatable/dismissModal()``, or by the
    /// presented coordinator calling ``Coordinatable/dismissCoordinator()``.
    ///
    /// - Parameters:
    ///   - destination: The destination to present.
    ///   - type: The modal presentation style. Defaults to `.sheet`.
    ///   - policy: See ``present(_:as:policy:onDismiss:)``. When the
    ///     policy skips the presentation, this returns immediately.
    func presentAndWait(
        _ destination: Destinations,
        as type: ModalPresentationType = .sheet,
        policy: RoutePolicy = .always
    ) async {
        guard !policySkips(destination, policy: policy, as: type.presentationType) else { return }
        let dest = performRoute(
            to: destination,
            as: type.presentationType,
            configuration: type.configuration,
            onDismiss: { }
        )
        await dest.resolution.awaitResolution()
    }

    /// Presents a destination modally and suspends until it is dismissed,
    /// returning the value the presented coordinator handed back.
    ///
    /// The presented coordinator delivers the result with
    /// ``Coordinatable/dismissCoordinator(returning:)``. Any other form of
    /// dismissal — an interactive swipe, ``Coordinatable/dismissModal()``,
    /// a plain ``Coordinatable/dismissCoordinator()`` — resumes with `nil`,
    /// so cancellation is handled for free:
    ///
    /// ```swift
    /// guard let token = await present(.login, awaiting: AuthToken.self) else {
    ///     return // user backed out
    /// }
    /// session.store(token)
    /// ```
    ///
    /// - Parameters:
    ///   - destination: The destination to present.
    ///   - type: The modal presentation style. Defaults to `.sheet`.
    ///   - policy: See ``present(_:as:policy:onDismiss:)``. When the
    ///     policy skips the presentation, this returns `nil` immediately.
    ///   - resultType: The type of value expected back.
    /// - Returns: The value passed to `dismissCoordinator(returning:)`,
    ///   or `nil` when the modal was dismissed without a result (or with a
    ///   result of a different type).
    func present<Result>(
        _ destination: Destinations,
        as type: ModalPresentationType = .sheet,
        policy: RoutePolicy = .always,
        awaiting resultType: Result.Type
    ) async -> Result? {
        guard !policySkips(destination, policy: policy, as: type.presentationType) else { return nil }
        let dest = performRoute(
            to: destination,
            as: type.presentationType,
            configuration: type.configuration,
            onDismiss: { }
        )
        await dest.resolution.awaitResolution()
        return dest.resolution.result as? Result
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

/// Hosts a flow's `NavigationStack`, activating the live path binding
/// only after the stack's first appearance.
///
/// `NavigationStack` drops a path that is non-empty on its very first
/// render — before `navigationDestination` has registered — and writes an
/// empty path back through the binding, silently erasing the pushed
/// state (observed on the iOS 27 beta; a deep link that replaces a
/// split-view column and pushes into the fresh flow in one shot lost
/// the push). Rendering the first frame with an empty constant path and
/// switching to the real binding on appear lands seeded paths reliably;
/// the activation is non-animated, and ordinary flows (empty initial
/// path) are unaffected.
private struct FlowNavigationStackView: View {
    let coordinator: any FlowCoordinatable
    let rootView: AnyView
    let destinationContent: (Destination) -> AnyView

    @State private var pathActive = false

    var body: some View {
        NavigationStack(
            path: pathActive ? coordinator.bindingStack(for: .push) : .constant([])
        ) {
            rootView
                .navigationDestination(for: Destination.self, destination: destinationContent)
        }
        .onAppear {
            guard !pathActive else { return }
            // One extra runloop hop: inside a NavigationSplitView column
            // the stack's onAppear can fire while the split view is still
            // installing the column, and a path applied in that window is
            // discarded (observed on the iOS 27 beta when swapping the
            // split style back to the native container).
            Task { @MainActor in
                guard !pathActive else { return }
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    pathActive = true
                }
            }
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
        FlowNavigationStackView(
            coordinator: _coordinator,
            rootView: view,
            destinationContent: { AnyView(self.wrappedView($0)) }
        )
        // Reset the stack identity when the root changes so that SwiftUI
        // drops any stale internal navigation state (e.g. lingering
        // navigation bar from a previous root's deep push hierarchy). The
        // reset also re-arms the deferred path activation below.
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
