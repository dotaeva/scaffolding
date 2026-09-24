//
//  FlowCoordinatable.swift
//  Scaffolding
//
//  Created by Alexandr Valíček on 22.09.2025.
//

import SwiftUI
import Observation
import os.log

/// A coordinator that owns a push stack, rendered as a `NavigationStack`.
///
/// Declare a ``FlowStack`` and route functions in the class body;
/// ``Scaffoldable(injectsCoordinator:codable:)`` generates the `Destinations` enum.
///
/// ```swift
/// @MainActor @Observable @Scaffoldable
/// final class HomeCoordinator: @MainActor FlowCoordinatable {
///     var stack = FlowStack<HomeCoordinator>(root: .home)
///
///     func home() -> some View { HomeView() }
///     func detail(id: Int) -> some View { DetailView(id: id) }
/// }
/// ```
///
/// Push with ``route(to:policy:)``, go back with ``pop()``, and present with
/// ``Coordinatable/present(_:as:policy:)``. A pushed child flow shares this
/// stack; a presented child gets its own. See <doc:Flows> and
/// <doc:Essentials>.
///
/// ## Topics
///
/// ### Pushing and Receiving Results
///
/// - ``route(to:policy:)``
/// - ``route(to:policy:expecting:)``
/// - ``route(to:policy:awaiting:)``
/// - ``route(to:policy:expecting:awaiting:)``
/// - ``routeAndWait(to:policy:)``
///
/// ### Going Back
///
/// - ``pop()``
/// - ``pop(_:)``
/// - ``popToRoot()``
/// - ``popToFirst(_:)``
/// - ``popToFirst(_:expecting:)``
/// - ``popToLast(_:)``
/// - ``popToLast(_:expecting:)``
///
/// ### Changing the Root
///
/// - ``setRoot(_:animation:)``
/// - ``setRoot(_:animation:expecting:)``
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
/// ### Reading Navigation State
///
/// - ``stack``
/// - ``depth``
/// - ``topDestination``
/// - ``isInStack(_:)``
/// - ``count(of:)``
///
/// ### Transition Animation
///
/// - ``setTransitionAnimation(_:)``
/// - ``setRootTransitionAnimation(_:)``
///
/// ### Type-Erased State
///
/// - ``anyStack``
///
/// ### Deprecated Compatibility
///
/// - ``popToFirst(_:_:)``
/// - ``popToLast(_:_:)``
/// - ``present(_:as:policy:onDismiss:)``
/// - ``present(_:as:policy:onDismiss:_:)``
/// - ``present(_:as:policy:onDismiss:expecting:)``
/// - ``presentAndWait(_:as:policy:)``
/// - ``replaceLast(with:)``
/// - ``replaceLast(with:onDismiss:)``
/// - ``route(to:policy:onDismiss:)``
/// - ``route(to:policy:onDismiss:_:)``
/// - ``route(to:policy:onDismiss:expecting:)``
/// - ``setRoot(_:animation:_:)``
@MainActor
public protocol FlowCoordinatable: Coordinatable where ViewType == FlowCoordinatableView {
    /// The flow's navigation state.
    ///
    /// Read it to inspect the flow; change it through the coordinator's methods.
    var stack: FlowStack<Self> { get }

    /// The stack as a read-only ``AnyFlowStack``.
    var anyStack: any AnyFlowStack { get }

    /// Framework plumbing: the stack, without resolving its initial destinations.
    var _uninitializedStack: any AnyFlowStack { get }
}

@MainActor
public extension FlowCoordinatable {
    var _dataId: ObjectIdentifier {
        stack.id
    }

    var _uninitializedStack: any AnyFlowStack { stack }

    var anyStack: any AnyFlowStack {
        stack.setup(for: self)
        return stack
    }

    /// The rendered flow and everything below it.
    ///
    /// Show the top-level coordinator's `view` once, usually in a `WindowGroup`.
    /// Child coordinators render through their parent.
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
        updateNavigationContext(navigationLayer: value, presentation: inheritedPresentation)
    }

    func setParent(_ parent: any Coordinatable) {
        stack.setParent(parent)
    }

    /// Sets the default animation for this coordinator's navigation changes.
    /// Pass `nil` to disable it.
    ///
    /// Same as ``setTransitionAnimation(_:)``.
    func setRootTransitionAnimation(_ animation: Animation?) {
        setTransitionAnimation(animation)
    }

    /// Sets the default animation for this coordinator's navigation changes.
    /// Pass `nil` to disable it.
    ///
    /// Covers root changes, pushes, pops, and modal changes. Override it for a
    /// chain with ``withNavigationTransaction(animation:_:)``.
    func setTransitionAnimation(_ animation: Animation?) {
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
        orderedModalDestinations().filter { $0.pushType == presentationType }
    }

    func orderedModalDestinations() -> [Destination] {
        var flattened: [Destination] = []

        if let rootDest = self._resolvedStack.root {
            traverseCoordinatable(rootDest.coordinatable) { nestedFlow in
                flattened.append(contentsOf: nestedFlow.orderedModalDestinations())
            }
        }

        for destination in self._resolvedStack.destinations {
            if destination.routeType.isModal {
                flattened.append(destination)
            }

            if destination.pushType == .push {
                traverseCoordinatable(destination.coordinatable) { nestedFlow in
                    flattened.append(contentsOf: nestedFlow.orderedModalDestinations())
                }
            }
        }

        return flattened
    }

    func removeModalDestination(withId id: UUID, type: PresentationType) {
        if let rootDest = self._resolvedStack.root {
            traverseCoordinatable(rootDest.coordinatable) { nestedFlow in
                nestedFlow.removeModalDestination(withId: id, type: type)
            }
        }

        removeOwnModals { $0.id == id && $0.pushType == type }

        for destination in _resolvedStack.destinations where destination.pushType == .push {
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
                        if let rootDest = nestedFlow._resolvedStack.root {
                            traverseRoots(rootDest.coordinatable)
                        }
                        flattenRecursively(nestedFlow._resolvedStack.destinations)
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
                    if let rootDest = flowCoordinator._resolvedStack.root {
                        traverseRoots(rootDest.coordinatable)
                    }

                    flattenRecursively(flowCoordinator._resolvedStack.destinations)
                }
            } else if let tabCoordinator = coordinatable as? any TabCoordinatable {
                if let selectedTabId = tabCoordinator._resolvedTabItems.selectedTab,
                   let selectedTab = tabCoordinator._resolvedTabItems.tabs.first(where: { $0.id == selectedTabId }) {
                    traverseRoots(selectedTab.coordinatable)
                }
            } else if let rootCoordinator = coordinatable as? any RootCoordinatable,
                      let rootDestination = rootCoordinator._resolvedRoot.root {
                traverseRoots(rootDestination.coordinatable)
            }
        }

        if let rootDest = self._resolvedStack.root {
            traverseRoots(rootDest.coordinatable)
        }

        flattenRecursively(self._resolvedStack.destinations)

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

        func collectDropped(_ destination: Destination) {
            dropped.append(destination)
        }

        func reconstructRecursively(for coordinator: any FlowCoordinatable) -> [Destination] {
            var newDestinations: [Destination] = []

            for originalDestination in coordinator._resolvedStack.destinations {
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
                                    if let rootDest = nestedFlow._resolvedStack.root {
                                        traverseAndReconstructRoots(rootDest.coordinatable)
                                    }
                                    let reconstructedNested = reconstructRecursively(for: nestedFlow)
                                    nestedFlow._resolvedStack.destinations = reconstructedNested
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
                    if let rootDest = flowCoordinator._resolvedStack.root {
                        traverseAndReconstructRoots(rootDest.coordinatable)
                    }

                    if flatIndex < flattenedDestinations.count || !flowCoordinator._resolvedStack.destinations.isEmpty {
                        let reconstructed = reconstructRecursively(for: flowCoordinator)
                        flowCoordinator._resolvedStack.destinations = reconstructed
                    } else {
                        flowCoordinator._resolvedStack.destinations = []
                    }
                }
            } else if let tabCoordinator = coordinatable as? any TabCoordinatable {
                if let selectedTabId = tabCoordinator._resolvedTabItems.selectedTab,
                   let selectedTab = tabCoordinator._resolvedTabItems.tabs.first(where: { $0.id == selectedTabId }) {
                    traverseAndReconstructRoots(selectedTab.coordinatable)
                }
            } else if let rootCoordinator = coordinatable as? any RootCoordinatable,
                      let rootDestination = rootCoordinator._resolvedRoot.root {
                traverseAndReconstructRoots(rootDestination.coordinatable)
            }
        }

        if let rootDest = self._resolvedStack.root {
            traverseAndReconstructRoots(rootDest.coordinatable)
        }

        let reconstructed = reconstructRecursively(for: self)
        self._resolvedStack.destinations = reconstructed

        // Topmost first, matching the order the programmatic pop family
        // resolves in. `resolveDismissal()` is single-shot, so a
        // destination already resolved by a `pop()` that SwiftUI is only
        // now catching up with is a no-op here.
        resolveDismissals(dropped)
    }
}

@MainActor
private extension FlowCoordinatable {
    func traverseCoordinatable(_ coordinatable: (any Coordinatable)?, action: (any FlowCoordinatable) -> Void) {
        guard let coordinatable = coordinatable else { return }

        if let flowCoordinator = coordinatable as? any FlowCoordinatable {
            action(flowCoordinator)
        } else if let tabCoordinator = coordinatable as? any TabCoordinatable {
            if let selectedTabId = tabCoordinator._resolvedTabItems.selectedTab,
               let selectedTab = tabCoordinator._resolvedTabItems.tabs.first(where: { $0.id == selectedTabId }) {
                traverseCoordinatable(selectedTab.coordinatable, action: action)
            }
        } else if let rootCoordinator = coordinatable as? any RootCoordinatable,
                  let rootDestination = rootCoordinator._resolvedRoot.root {
            traverseCoordinatable(rootDestination.coordinatable, action: action)
        }
    }


}

@MainActor
public extension FlowCoordinatable {
    /// Replaces the flow's root and removes every pushed and presented entry.
    ///
    /// The new root is built fresh, even for the same case. Removed entries
    /// resume their waiters with `nil`.
    ///
    /// - Parameters:
    ///   - destination: The new root.
    ///   - animation: An animation for this change, or `nil` for the default.
    /// - Returns: `self`, for chaining.
    @discardableResult
    func setRoot(_ destination: Destinations, animation: Animation? = nil) -> Self {
        stack.setup(for: self)
        let dest = destination.resolvedValue(for: self)
        stack.setRoot(root: dest, animation: animation)
        return self
    }

    /// Pushes a destination onto the stack.
    ///
    /// To present modally, use ``Coordinatable/present(_:as:policy:)``. To wait
    /// for a result, use ``route(to:policy:awaiting:)``.
    ///
    /// - Parameters:
    ///   - destination: The destination to push.
    ///   - policy: ``RoutePolicy/distinct`` skips the push when the same case is
    ///     already on top. Defaults to ``RoutePolicy/always``.
    /// - Returns: `self`, for chaining.
    @discardableResult
    func route(
        to destination: Destinations,
        policy: RoutePolicy = .always
    ) -> Self {
        guard !policySkips(destination, policy: policy, as: .push) else { return self }
        performRoute(to: destination, as: .push, onDismiss: { })
        return self
    }

    /// Deprecated. Use ``route(to:policy:awaiting:)`` instead.
    ///
    /// Await it with `awaiting: Void.self` and run the dismissal code after it.
    @available(*, deprecated, message: "Will be removed in a future update. Use await route with awaiting: instead; pass Void.self to wait without a result.")
    @discardableResult
    func route(
        to destination: Destinations,
        policy: RoutePolicy = .always,
        onDismiss: @escaping @MainActor () -> Void
    ) -> Self {
        guard !policySkips(destination, policy: policy, as: .push) else { return self }
        performRoute(to: destination, as: .push, onDismiss: onDismiss)
        return self
    }

    /// Presents a destination as a sheet or full-screen cover.
    ///
    /// The request is stored on this flow's stack and joins its host's modal
    /// queue. To wait for a result, use ``Coordinatable/present(_:as:policy:awaiting:)``.
    ///
    /// - Parameters:
    ///   - destination: The destination to present.
    ///   - type: `.sheet` (the default) or `.fullScreenCover`.
    ///   - policy: ``RoutePolicy/distinct`` skips the request when the same case
    ///     is already requested, including queued requests.
    /// - Returns: `self`, for chaining.
    @discardableResult
    func present(
        _ destination: Destinations,
        as type: ModalPresentationType = .sheet,
        policy: RoutePolicy = .always
    ) -> Self {
        guard !policySkips(destination, policy: policy, as: type.presentationType) else { return self }
        performRoute(
            to: destination,
            as: type.presentationType,
            configuration: type.configuration,
            onDismiss: { }
        )
        return self
    }

    /// Deprecated. Use ``Coordinatable/present(_:as:policy:awaiting:)`` instead.
    ///
    /// Await it with `awaiting: Void.self` and run the dismissal code after it.
    @available(*, deprecated, message: "Will be removed in a future update. Use await present with awaiting: instead; pass Void.self to wait without a result.")
    @discardableResult
    func present(
        _ destination: Destinations,
        as type: ModalPresentationType = .sheet,
        policy: RoutePolicy = .always,
        onDismiss: @escaping @MainActor () -> Void
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

    /// Removes the last pushed or presented entry.
    ///
    /// The last entry may be a modal. On an empty stack, this dismisses the
    /// coordinator instead. Use ``pop(_:)`` to stop at the root, or
    /// ``Coordinatable/dismissPresentedModal()`` to close only the visible modal.
    ///
    /// - Returns: `self`, for chaining.
    @discardableResult
    func pop() -> Self {
        stack.setup(for: self)
        stack.pop()
        return self
    }

    /// Removes every pushed and presented entry above the root.
    ///
    /// - Returns: `self`, for chaining.
    @discardableResult
    func popToRoot() -> Self {
        stack.setup(for: self)
        stack.popToRoot()
        return self
    }

    /// Returns to the first entry matching a case and removes everything above it.
    ///
    /// Checks the root first, then entries from the bottom. Does nothing when
    /// no entry matches.
    ///
    /// - Parameter destination: The case to return to.
    /// - Returns: `self`, for chaining.
    @discardableResult
    func popToFirst(_ destination: Destinations.Meta) -> Self {
        stack.setup(for: self)
        _ = stack.popToFirst(destination)
        return self
    }

    /// Returns to the last entry matching a case and removes everything above it.
    ///
    /// Falls back to the root when only the root matches. Does nothing when no
    /// entry matches.
    ///
    /// - Parameter destination: The case to return to.
    /// - Returns: `self`, for chaining.
    @discardableResult
    func popToLast(_ destination: Destinations.Meta) -> Self {
        stack.setup(for: self)
        _ = stack.popToLast(destination)
        return self
    }

    /// Returns whether a pushed or presented entry matches a case.
    ///
    /// The root is not checked. Associated values are ignored.
    func isInStack(_ destination: Destinations.Meta) -> Bool {
        _resolvedStack.destinations.contains { dest in
            guard let destMeta = dest.meta as? Self.Destinations.Meta else { return false }
            return destMeta == destination
        }
    }

    /// The number of screens pushed above the root.
    ///
    /// Modals are not counted. `0` means the flow shows its root.
    var depth: Int {
        _resolvedStack.destinations.count { $0.pushType == .push }
    }

    /// The case of the top pushed screen, or of the root when nothing is pushed.
    ///
    /// Modals are ignored.
    var topDestination: Destinations.Meta? {
        if let last = _resolvedStack.destinations.last(where: { $0.pushType == .push }) {
            return last.meta as? Destinations.Meta
        }
        return _resolvedStack.root?.meta as? Destinations.Meta
    }

    /// Whether this flow has a modal request of its own, visible or queued.
    var isPresentingModal: Bool {
        _resolvedStack.destinations.contains {
            $0.pushType == .sheet || $0.pushType == .fullScreenCover
        }
    }

    /// The number of pushed and presented entries matching a case.
    ///
    /// The root is not counted. Associated values are ignored.
    func count(of destination: Destinations.Meta) -> Int {
        _resolvedStack.destinations.count { dest in
            guard let destMeta = dest.meta as? Self.Destinations.Meta else { return false }
            return destMeta == destination
        }
    }

    /// Removes up to `count` entries from the top of the stack.
    ///
    /// Stops at the root; unlike ``pop()``, it never dismisses the coordinator.
    ///
    /// - Parameter count: The maximum number of entries to remove.
    /// - Returns: `self`, for chaining.
    @discardableResult
    func pop(_ count: Int) -> Self {
        stack.setup(for: self)
        stack.pop(count: count)
        return self
    }

    /// Deprecated. Use ``pop()`` and then ``route(to:policy:)`` instead.
    ///
    /// Pop only when `depth > 0` and no modal is queued; use
    /// ``setRoot(_:animation:)`` for a new flow root. See
    /// <doc:Flows#Replace-the-root-or-the-top-screen>.
    @available(*, deprecated, message: "Will be removed in a future update. Use pop() followed by route(to:), or setRoot(_:) to replace the whole flow.")
    @discardableResult
    func replaceLast(
        with destination: Destinations
    ) -> Self {
        stack.setup(for: self)
        guard let index = stack.destinations.lastIndex(where: { $0.pushType == .push }) else {
            return route(to: destination)
        }

        let dest = makeDestination(for: destination, as: .push, onDismiss: { })
        let replaced = stack.destinations[index]
        withScaffoldingAnimation(stack.animation) { stack.destinations[index] = dest }
        replaced.resolveDismissal()
        return self
    }

    /// Deprecated. Use ``pop()`` and then ``route(to:policy:)`` instead.
    ///
    /// Pop only when `depth > 0` and no modal is queued; use
    /// ``setRoot(_:animation:)`` for a new flow root. See
    /// <doc:Flows#Replace-the-root-or-the-top-screen>.
    @available(*, deprecated, message: "Will be removed in a future update. Use pop() followed by route(to:), or setRoot(_:) to replace the whole flow.")
    @discardableResult
    func replaceLast(
        with destination: Destinations,
        onDismiss: @escaping @MainActor () -> Void
    ) -> Self {
        stack.setup(for: self)
        guard let index = stack.destinations.lastIndex(where: { $0.pushType == .push }) else {
            return route(to: destination, onDismiss: onDismiss)
        }

        let dest = makeDestination(for: destination, as: .push, onDismiss: onDismiss)
        let replaced = stack.destinations[index]
        withScaffoldingAnimation(stack.animation) { stack.destinations[index] = dest }
        replaced.resolveDismissal()
        return self
    }
}

@MainActor
public extension FlowCoordinatable {
    /// Deprecated. Use ``route(to:policy:expecting:)`` instead.
    ///
    /// To also wait for dismissal, use ``route(to:policy:expecting:awaiting:)``.
    @discardableResult
    @available(*, deprecated, message: "Will be removed in a future update. Use expecting: for child access; combine it with awaiting: for dismissal/results.")
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

    /// Deprecated. Use ``Coordinatable/present(_:as:policy:expecting:)`` instead.
    ///
    /// To also wait for dismissal, use ``Coordinatable/present(_:as:policy:expecting:awaiting:)``.
    @discardableResult
    @available(*, deprecated, message: "Will be removed in a future update. Use expecting: for child access; combine it with awaiting: for dismissal/results.")
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

    /// Deprecated. Use ``setRoot(_:animation:expecting:)`` instead.
    @discardableResult
    @available(*, deprecated, message: "Will be removed in a future update. Use the expecting: overload to access the child coordinator.")
    func setRoot<T: Coordinatable>(
        _ destination: Destinations,
        animation: Animation? = nil,
        _ action: @escaping @MainActor (T) -> Void
    ) -> Self {
        stack.setup(for: self)
        let dest = destination.resolvedValue(for: self)
        stack.setRoot(root: dest, animation: animation)
        if let coordinator = dest.coordinatable as? T {
            action(coordinator)
        }
        return self
    }

    /// Deprecated. Use ``popToFirst(_:expecting:)`` instead.
    @discardableResult
    @available(*, deprecated, message: "Will be removed in a future update. Use the expecting: overload to access the child coordinator.")
    func popToFirst<T: Coordinatable>(
        _ destination: Destinations.Meta,
        _ action: @escaping @MainActor (T) -> Void
    ) -> Self {
        stack.setup(for: self)
        if let dest = stack.popToFirst(destination),
           let coordinator = dest.coordinatable as? T {
            action(coordinator)
        }
        return self
    }

    /// Deprecated. Use ``popToLast(_:expecting:)`` instead.
    @discardableResult
    @available(*, deprecated, message: "Will be removed in a future update. Use the expecting: overload to access the child coordinator.")
    func popToLast<T: Coordinatable>(
        _ destination: Destinations.Meta,
        _ action: @escaping @MainActor (T) -> Void
    ) -> Self {
        stack.setup(for: self)
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
        stack.setup(for: self)
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
        dest.coordinatable?.attach(to: self, navigationLayer: pushType == .push, presentation: pushType)

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

        return dest
    }

    /// Whether a `.distinct` policy should skip this navigation request.
    func policySkips(
        _ destination: Destinations,
        policy: RoutePolicy,
        as pushType: PresentationType
    ) -> Bool {
        stack.setup(for: self)
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
    /// Pushes a destination and returns the child as `T`, or `nil` for a view
    /// route or another type. The navigation happens either way.
    ///
    /// A ``RoutePolicy/distinct`` skip also returns `nil`, without pushing.
    ///
    /// ```swift
    /// route(to: .settings, expecting: SettingsCoordinator.self)?.route(to: .account)
    /// ```
    ///
    /// - Returns: The pushed child, or `nil`.
    func route<T: Coordinatable>(
        to destination: Destinations,
        policy: RoutePolicy = .always,
        expecting coordinatorType: T.Type
    ) -> T? {
        guard !policySkips(destination, policy: policy, as: .push) else { return nil }
        let dest = performRoute(to: destination, as: .push, onDismiss: { })
        return dest.coordinatable as? T
    }

    /// Deprecated. Use ``route(to:policy:expecting:awaiting:)`` instead.
    ///
    /// Run the dismissal code after awaiting the returned `result()`.
    @available(*, deprecated, message: "Will be removed in a future update. Use expecting: with awaiting: to get the child immediately and await its result.")
    func route<T: Coordinatable>(
        to destination: Destinations,
        policy: RoutePolicy = .always,
        onDismiss: @escaping @MainActor () -> Void,
        expecting coordinatorType: T.Type
    ) -> T? {
        guard !policySkips(destination, policy: policy, as: .push) else { return nil }
        let dest = performRoute(to: destination, as: .push, onDismiss: onDismiss)
        return dest.coordinatable as? T
    }

    /// Presents a destination and returns the child as `T`, or `nil` for a view
    /// route or another type. The navigation happens either way.
    ///
    /// A ``RoutePolicy/distinct`` skip also returns `nil`, without presenting.
    func present<T: Coordinatable>(
        _ destination: Destinations,
        as type: ModalPresentationType = .sheet,
        policy: RoutePolicy = .always,
        expecting coordinatorType: T.Type
    ) -> T? {
        guard !policySkips(destination, policy: policy, as: type.presentationType) else { return nil }
        let dest = performRoute(
            to: destination,
            as: type.presentationType,
            configuration: type.configuration,
            onDismiss: { }
        )
        return dest.coordinatable as? T
    }

    /// Deprecated. Use ``Coordinatable/present(_:as:policy:expecting:awaiting:)`` instead.
    ///
    /// Run the dismissal code after awaiting the returned `result()`.
    @available(*, deprecated, message: "Will be removed in a future update. Use expecting: with awaiting: to get the child immediately and await its result.")
    func present<T: Coordinatable>(
        _ destination: Destinations,
        as type: ModalPresentationType = .sheet,
        policy: RoutePolicy = .always,
        onDismiss: @escaping @MainActor () -> Void,
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

    /// Replaces the flow's root and returns the child as `T`, or `nil` for a
    /// view route or another type. The navigation happens either way.
    ///
    /// Removes every pushed and presented entry, like ``setRoot(_:animation:)``.
    func setRoot<T: Coordinatable>(
        _ destination: Destinations,
        animation: Animation? = nil,
        expecting coordinatorType: T.Type
    ) -> T? {
        stack.setup(for: self)
        let dest = destination.resolvedValue(for: self)
        stack.setRoot(root: dest, animation: animation)
        return dest.coordinatable as? T
    }

    /// Returns to the first entry matching a case and returns its child as `T`.
    ///
    /// Returns `nil` for a view route or another type. With no match, nothing
    /// is removed and the result is `nil`.
    func popToFirst<T: Coordinatable>(
        _ destination: Destinations.Meta,
        expecting coordinatorType: T.Type
    ) -> T? {
        stack.setup(for: self)
        return stack.popToFirst(destination)?.coordinatable as? T
    }

    /// Returns to the last entry matching a case and returns its child as `T`.
    ///
    /// Returns `nil` for a view route or another type. With no match, nothing
    /// is removed and the result is `nil`.
    func popToLast<T: Coordinatable>(
        _ destination: Destinations.Meta,
        expecting coordinatorType: T.Type
    ) -> T? {
        stack.setup(for: self)
        return stack.popToLast(destination)?.coordinatable as? T
    }
}

// MARK: - Awaitable navigation

@MainActor
public extension FlowCoordinatable {
    /// Pushes a destination and returns its child and a result waiter without
    /// suspending.
    ///
    /// Configure the child, then await `result()`:
    ///
    /// ```swift
    /// let (picker, result) = route(
    ///     to: .picker, expecting: PickerCoordinator.self, awaiting: Item.self
    /// )
    /// picker?.route(to: .favorites)
    /// let item = await result()
    /// ```
    ///
    /// Called from a cancelled task, it pushes nothing and returns `nil` for both.
    ///
    /// - Parameters:
    ///   - destination: The destination to push.
    ///   - policy: A ``RoutePolicy/distinct`` skip returns a `nil` child and a
    ///     `result()` that returns `nil` immediately.
    ///   - coordinatorType: The expected child type.
    ///   - resultType: The expected result type. Use `Void.self` to wait only.
    /// - Returns: The child, or `nil` for a view route or another type, and a
    ///   `result()` closure. `result()` returns the dismissal value, or `nil`
    ///   for dismissal without one, a type mismatch, or cancellation of the
    ///   waiting task, which leaves the screen in place. It keeps returning the
    ///   same value after dismissal.
    func route<T: Coordinatable, Result>(
        to destination: Destinations,
        policy: RoutePolicy = .always,
        expecting coordinatorType: T.Type,
        awaiting resultType: Result.Type
    ) -> (coordinator: T?, result: @MainActor () async -> Result?) {
        guard !Task.isCancelled,
              !policySkips(destination, policy: policy, as: .push) else {
            return (nil, { nil })
        }
        let dest = performRoute(to: destination, as: .push, onDismiss: { })
        return (dest.coordinatable as? T, dest.resolution.resultWaiter(for: resultType))
    }

    /// Presents a destination and returns its child and a result waiter without
    /// suspending.
    ///
    /// ```swift
    /// let (settings, result) = present(
    ///     .settings, expecting: SettingsCoordinator.self, awaiting: Void.self
    /// )
    /// settings?.route(to: .account)
    /// _ = await result()
    /// ```
    ///
    /// The child, `result()`, cancellation, and ``RoutePolicy/distinct`` behave
    /// as in ``route(to:policy:expecting:awaiting:)``.
    func present<T: Coordinatable, Result>(
        _ destination: Destinations,
        as type: ModalPresentationType = .sheet,
        policy: RoutePolicy = .always,
        expecting coordinatorType: T.Type,
        awaiting resultType: Result.Type
    ) -> (coordinator: T?, result: @MainActor () async -> Result?) {
        guard !Task.isCancelled,
              !policySkips(destination, policy: policy, as: type.presentationType) else {
            return (nil, { nil })
        }
        let dest = performRoute(
            to: destination,
            as: type.presentationType,
            configuration: type.configuration,
            onDismiss: { }
        )
        return (dest.coordinatable as? T, dest.resolution.resultWaiter(for: resultType))
    }

    /// Pushes a destination and suspends until it leaves, returning its result.
    ///
    /// A screen returns a value with ``Destination/dismiss(returning:)``; a child
    /// coordinator uses ``Coordinatable/dismissCoordinator(returning:)``.
    ///
    /// ```swift
    /// let item = await route(to: .picker, awaiting: Item.self)
    /// ```
    ///
    /// - Parameters:
    ///   - destination: The destination to push.
    ///   - policy: A ``RoutePolicy/distinct`` skip returns `nil` immediately.
    ///   - resultType: The expected result type. Use `Void.self` to wait only.
    /// - Returns: The result, or `nil` for a back action or ``pop()``, a type
    ///   mismatch, a skipped push, or cancellation. Cancellation leaves the
    ///   screen in place.
    func route<Result>(
        to destination: Destinations,
        policy: RoutePolicy = .always,
        awaiting resultType: Result.Type
    ) async -> Result? {
        guard !Task.isCancelled else { return nil }
        guard !policySkips(destination, policy: policy, as: .push) else { return nil }
        let dest = performRoute(to: destination, as: .push, onDismiss: { })
        await dest.resolution.awaitResolution()
        return Task.isCancelled ? nil : dest.resolution.result as? Result
    }

    /// Pushes a destination and suspends until it leaves the stack.
    ///
    /// Resumes once, however the screen leaves: a pop, a back swipe, a root
    /// swap, or the flow's dismissal. Cancelling the task also resumes it and
    /// leaves the screen in place. For a result, use ``route(to:policy:awaiting:)``.
    ///
    /// ```swift
    /// await routeAndWait(to: .help)
    /// ```
    ///
    /// - Parameters:
    ///   - destination: The destination to push.
    ///   - policy: A ``RoutePolicy/distinct`` skip returns immediately.
    func routeAndWait(
        to destination: Destinations,
        policy: RoutePolicy = .always
    ) async {
        guard !Task.isCancelled else { return }
        guard !policySkips(destination, policy: policy, as: .push) else { return }
        let dest = performRoute(to: destination, as: .push, onDismiss: { })
        await dest.resolution.awaitResolution()
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
        guard !policySkips(destination, policy: policy, as: type.presentationType) else { return }
        let dest = performRoute(
            to: destination,
            as: type.presentationType,
            configuration: type.configuration,
            onDismiss: { }
        )
        await dest.resolution.awaitResolution()
    }

    /// Presents a destination and suspends until it is dismissed, returning its
    /// result.
    ///
    /// The presented content returns a value with ``Destination/dismiss(returning:)``
    /// or ``Coordinatable/dismissCoordinator(returning:)``. A swipe,
    /// ``Coordinatable/dismissPresentedModal()``, or a plain
    /// ``Coordinatable/dismissCoordinator()`` returns `nil`.
    ///
    /// ```swift
    /// guard let token = await present(.login, awaiting: AuthToken.self) else { return }
    /// session.store(token)
    /// ```
    ///
    /// - Parameters:
    ///   - destination: The destination to present.
    ///   - type: `.sheet` (the default) or `.fullScreenCover`.
    ///   - policy: A ``RoutePolicy/distinct`` skip returns `nil` immediately.
    ///   - resultType: The expected result type. Use `Void.self` to wait only.
    /// - Returns: The result, or `nil` for dismissal without one, a type
    ///   mismatch, a skipped request, or cancellation. Cancellation leaves the
    ///   modal in place.
    func present<Result>(
        _ destination: Destinations,
        as type: ModalPresentationType = .sheet,
        policy: RoutePolicy = .always,
        awaiting resultType: Result.Type
    ) async -> Result? {
        guard !Task.isCancelled else { return nil }
        guard !policySkips(destination, policy: policy, as: type.presentationType) else { return nil }
        let dest = performRoute(
            to: destination,
            as: type.presentationType,
            configuration: type.configuration,
            onDismiss: { }
        )
        await dest.resolution.awaitResolution()
        return Task.isCancelled ? nil : dest.resolution.result as? Result
    }
}

@MainActor
extension FlowCoordinatable {
    func setPresentedAs(_ type: PresentationType) {
        inheritPresentation(type)
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

/// The view that renders a ``FlowCoordinatable``.
///
/// Get it from the coordinator's ``Coordinatable/view``; don't create it directly.
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
        if let rootView = _coordinator._resolvedStack.root?.view {
            flowCoordinatableView(view: AnyView(rootView))
        } else if let c = _coordinator._resolvedStack.root?.coordinatable {
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
        .id(_coordinator._resolvedStack.root?.id)
        .applySheets(from: _coordinator, modalContent: wrappedView)
        .applyFullScreenCovers(from: _coordinator, modalContent: wrappedView)
    }

    public var body: some View {
        _coordinator.customize(
            AnyView(
                Group {
                    if _coordinator._resolvedStack.hasLayerNavigationCoordinator {
                        if let rootView = _coordinator._resolvedStack.root?.view {
                            AnyView(rootView)
                        } else if let c = _coordinator._resolvedStack.root?.coordinatable {
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
        .id(_coordinator._resolvedStack.id)
    }
}

@MainActor
extension FlowCoordinatable {
    var _stack: any _MutableFlowStack { stack }
    var _resolvedStack: any _MutableFlowStack {
        stack.setup(for: self)
        return stack
    }
}
