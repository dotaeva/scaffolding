import SwiftUI

@MainActor
public extension Coordinatable {
    /// Whether this coordinator owns a modal request, visible or queued.
    var isPresentingModal: Bool { !ownModalDestinations.isEmpty }

    @discardableResult
    func present(
        _ destination: Destinations,
        as type: ModalPresentationType = .sheet,
        policy: RoutePolicy = .always
    ) -> Self {
        _ = makeModal(destination, as: type, policy: policy)
        return self
    }

    func present<T: Coordinatable>(
        _ destination: Destinations,
        as type: ModalPresentationType = .sheet,
        policy: RoutePolicy = .always,
        expecting coordinatorType: T.Type
    ) -> T? {
        makeModal(destination, as: type, policy: policy)?.coordinatable as? T
    }

    func present<Result>(
        _ destination: Destinations,
        as type: ModalPresentationType = .sheet,
        policy: RoutePolicy = .always,
        awaiting resultType: Result.Type
    ) async -> Result? {
        guard !Task.isCancelled, let destination = makeModal(destination, as: type, policy: policy) else { return nil }
        return await destination.resolution.resultWaiter(for: resultType)()
    }

    func present<T: Coordinatable, Result>(
        _ destination: Destinations,
        as type: ModalPresentationType = .sheet,
        policy: RoutePolicy = .always,
        expecting coordinatorType: T.Type,
        awaiting resultType: Result.Type
    ) -> (coordinator: T?, result: @MainActor () async -> Result?) {
        guard !Task.isCancelled, let destination = makeModal(destination, as: type, policy: policy) else { return (nil, { nil }) }
        return (destination.coordinatable as? T, destination.resolution.resultWaiter(for: resultType))
    }

    /// Closes the visible request of this coordinator's presentation host.
    ///
    /// The next queued request, if any, then shows. In a shared flow stack the
    /// visible request may belong to a nested flow; this closes it anyway. Its
    /// waiters resume with `nil`. Does nothing when the host has no requests.
    ///
    /// - Returns: `self`, for chaining.
    @discardableResult
    func dismissPresentedModal() -> Self {
        guard let destination = presentationQueue.first else { return self }
        destination.parent?.removeOwnModals { $0.id == destination.id }
        return self
    }

    /// Removes this coordinator's requests that wait behind the host's visible
    /// request.
    ///
    /// The visible request stays. Each removed request's waiters resume with
    /// `nil`, as for an ordinary dismissal.
    ///
    /// - Returns: `self`, for chaining.
    @discardableResult
    func cancelPendingModals() -> Self {
        let presentedID = presentationQueue.first?.id
        removeOwnModals { $0.id != presentedID }
        return self
    }

    /// The number of this coordinator's requests waiting behind the host's
    /// visible request.
    var pendingModalCount: Int {
        let presentedID = presentationQueue.first?.id
        return ownModalDestinations.count { $0.id != presentedID }
    }
}

// MARK: - Deprecated presentation compatibility

@MainActor
public extension Coordinatable {
    /// Deprecated. Use ``Coordinatable/present(_:as:policy:awaiting:)`` instead.
    ///
    /// Pass `Void.self` and put the `onDismiss` code after the `await`.
    @available(*, deprecated, message: "Will be removed in a future update. Use await present with awaiting: instead; pass Void.self to wait without a result.")
    @discardableResult
    func present(
        _ destination: Destinations,
        as type: ModalPresentationType = .sheet,
        policy: RoutePolicy = .always,
        onDismiss: @escaping @MainActor () -> Void
    ) -> Self {
        _ = makeModal(destination, as: type, policy: policy, onDismiss: onDismiss)
        return self
    }

    /// Deprecated. Use ``Coordinatable/present(_:as:policy:expecting:)`` instead.
    ///
    /// Add `awaiting:` when the call also relied on dismissal.
    @discardableResult
    @available(*, deprecated, message: "Will be removed in a future update. Use expecting: for child access; combine it with awaiting: for dismissal/results.")
    func present<T: Coordinatable>(
        _ destination: Destinations,
        as type: ModalPresentationType = .sheet,
        policy: RoutePolicy = .always,
        onDismiss: @escaping @MainActor () -> Void = { },
        _ action: @escaping @MainActor (T) -> Void
    ) -> Self {
        guard let dest = makeModal(destination, as: type, policy: policy, onDismiss: onDismiss) else { return self }
        if let coordinator = dest.coordinatable as? T {
            action(coordinator)
        }
        return self
    }

    /// Deprecated. Use ``Coordinatable/present(_:as:policy:expecting:awaiting:)`` instead.
    ///
    /// Pass `Void.self` and put the `onDismiss` code after `await result()`.
    @available(*, deprecated, message: "Will be removed in a future update. Use expecting: with awaiting: to get the child immediately and await its result.")
    func present<T: Coordinatable>(
        _ destination: Destinations,
        as type: ModalPresentationType = .sheet,
        policy: RoutePolicy = .always,
        onDismiss: @escaping @MainActor () -> Void,
        expecting coordinatorType: T.Type
    ) -> T? {
        makeModal(destination, as: type, policy: policy, onDismiss: onDismiss)?.coordinatable as? T
    }

    /// Deprecated. Use ``Coordinatable/present(_:as:policy:awaiting:)`` instead.
    ///
    /// Pass `Void.self` to wait for dismissal only.
    @available(*, deprecated, message: "Will be removed in a future update. Use await present with awaiting: Void.self to wait for dismissal, or awaiting: Result.self to receive a result.")
    func presentAndWait(
        _ destination: Destinations,
        as type: ModalPresentationType = .sheet,
        policy: RoutePolicy = .always
    ) async {
        _ = await present(destination, as: type, policy: policy, awaiting: Void.self)
    }
}

@MainActor
extension Coordinatable {
    var ownModalDestinations: [Destination] {
        if let flow = self as? any FlowCoordinatable {
            return flow._resolvedStack.destinations.filter { $0.routeType.isModal }
        }
        if let root = self as? any RootCoordinatable { return root._resolvedRoot.modals }
        if let tabs = self as? any TabCoordinatable { return tabs._resolvedTabItems.modals }
        if let split = self as? any SplitCoordinatable { return split._resolvedSplitColumns.modals }
        return []
    }

    var presentationQueue: [Destination] {
        if let flow = self as? any FlowCoordinatable {
            var host = flow
            var current: any Coordinatable = flow
            var visited = Set<ObjectIdentifier>()
            while current.hasLayerNavigationCoordinatable,
                  visited.insert(ObjectIdentifier(current)).inserted,
                  let parent = current.parent {
                if let parentFlow = parent as? any FlowCoordinatable { host = parentFlow }
                current = parent
            }
            return host.orderedModalDestinations()
        }
        return ownModalDestinations
    }

    func makeModal(
        _ route: Destinations,
        as type: ModalPresentationType,
        policy: RoutePolicy,
        onDismiss: @escaping @MainActor () -> Void = {}
    ) -> Destination? {
        guard !modalPolicySkips(route, policy: policy) else { return nil }
        return performPresent(route, as: type, onDismiss: onDismiss)
    }

    func modalPolicySkips(_ route: Destinations, policy: RoutePolicy) -> Bool {
        guard route.isAvailable else { return true }
        guard case .distinct = policy else { return false }
        return ownModalDestinations.contains { ($0.meta as? Destinations.Meta) == route.meta }
    }

    /// Shared by ordinary, legacy, and restored presentations.
    /// Callers check availability and policy before constructing a destination.
    @discardableResult
    func performPresent(
        _ route: Destinations,
        as type: ModalPresentationType,
        onDismiss: @escaping @MainActor () -> Void
    ) -> Destination {
        // Resolve initial state before running the requested route factory.
        _ = ownModalDestinations
        var destination = route.resolvedValue(for: self)
        destination.setOnDismiss(onDismiss)
        destination.setPushType(type.presentationType)
        destination.setRouteType(.from(presentationType: type.presentationType))
        destination.setModalConfiguration(type.configuration)
        destination.coordinatable?.attach(to: self, navigationLayer: false, presentation: type.presentationType)
        withNavigationAnimation {
            if let flow = self as? any FlowCoordinatable { flow._stack.destinations.append(destination) }
            else if let root = self as? any RootCoordinatable { root._root.modals.append(destination) }
            else if let tabs = self as? any TabCoordinatable { tabs._tabItems.modals.append(destination) }
            else if let split = self as? any SplitCoordinatable { split._columns.modals.append(destination) }
        }
        return destination
    }

    func removeOwnModals(where shouldRemove: (Destination) -> Bool) {
        var removed: [Destination] = []
        withNavigationAnimation {
            if let flow = self as? any FlowCoordinatable {
                removed = flow._resolvedStack.destinations.filter { $0.routeType.isModal && shouldRemove($0) }
                let ids = Set(removed.map(\.id))
                flow._resolvedStack.destinations.removeAll { ids.contains($0.id) }
            } else if let root = self as? any RootCoordinatable {
                removed = root._resolvedRoot.modals.filter(shouldRemove)
                root._resolvedRoot.modals.removeAll(where: shouldRemove)
            } else if let tabs = self as? any TabCoordinatable {
                removed = tabs._resolvedTabItems.modals.filter(shouldRemove)
                tabs._resolvedTabItems.modals.removeAll(where: shouldRemove)
            } else if let split = self as? any SplitCoordinatable {
                removed = split._resolvedSplitColumns.modals.filter(shouldRemove)
                split._resolvedSplitColumns.modals.removeAll(where: shouldRemove)
            }
        }
        resolveDismissals(removed)
    }

    @discardableResult
    func withNavigationAnimation<Value>(_ body: () -> Value) -> Value {
        if let flow = self as? any FlowCoordinatable { return withScaffoldingAnimation(flow._stack.animation, body) }
        if let root = self as? any RootCoordinatable { return withScaffoldingAnimation(root._root.animation, body) }
        if let tabs = self as? any TabCoordinatable { return withScaffoldingAnimation(tabs._tabItems.animation, body) }
        if let split = self as? any SplitCoordinatable { return withScaffoldingAnimation(split._columns.animation, body) }
        return body()
    }
}
