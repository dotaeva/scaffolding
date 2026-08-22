//
//  Coordinatable.swift
//  Scaffolding
//
//  Created by Alexandr Valíček on 22.09.2025.
//

import SwiftUI
import os.log

/// The core protocol that all coordinators conform to.
///
/// `Coordinatable` provides the shared surface every coordinator type
/// (``FlowCoordinatable``, ``TabCoordinatable``, ``RootCoordinatable``)
/// builds upon: an associated `Destinations` enum, identity, parent
/// tracking, and the ability to produce a SwiftUI view.
///
/// You do not conform to `Coordinatable` directly — use one of the
/// three specialized protocols instead.
@MainActor
public protocol Coordinatable: AnyObject, Identifiable {
    associatedtype Destinations: Destinationable where Destinations.Owner == Self
    associatedtype ViewType: View
    associatedtype CustomizeContentView: View

    var _dataId: ObjectIdentifier { get }
    var parent: (any Coordinatable)? { get }
    var hasLayerNavigationCoordinatable: Bool { get }
    var view: ViewType { get }
    func setHasLayerNavigationCoordinatable(_ value: Bool)
    func setParent(_ value: any Coordinatable)

    /// Wraps the coordinator's content view with additional modifiers.
    ///
    /// Override this method to apply shared modifiers — such as toolbars,
    /// overlays, or environment values — to every screen the coordinator
    /// presents.
    ///
    /// - Parameter view: The type-erased content view produced by the
    ///   coordinator.
    /// - Returns: A modified view.
    func customize(_ view: AnyView) -> CustomizeContentView

    /// Captures this coordinator's navigation state as a codable node,
    /// or `nil` when the coordinator's `Destinations` are not `Codable`.
    ///
    /// Do not implement or call this directly — use
    /// ``captureNavigationState()``. A default implementation is provided
    /// for every coordinator type.
    func _captureNavigationStateNode() -> NavigationStateNode?

    /// Restores navigation state captured by
    /// ``_captureNavigationStateNode()``.
    ///
    /// Do not implement or call this directly — use
    /// ``restoreNavigationState(from:)``. A default implementation is
    /// provided for every coordinator type.
    func _restoreNavigationStateNode(_ node: NavigationStateNode)
}

@MainActor
public extension Coordinatable {
    /// Whether this coordinator should be injected into descendant
    /// views' environment (`@Environment(MyCoordinator.self)`).
    ///
    /// Defaults to `true`. Override by passing
    /// `@Scaffoldable(injectsCoordinator: false)`, which causes the
    /// macro to emit a property returning `false`.
    nonisolated var _injectsCoordinator: Bool { true }

    func customize(_ view: AnyView) -> some View {
        view
    }

    /// Dismisses this coordinator from its parent's navigation hierarchy.
    ///
    /// If the coordinator is the root of a ``FlowCoordinatable`` stack, the
    /// entire flow is dismissed. If it lives inside a stack as a pushed
    /// destination, only that destination is removed. Tab children cannot
    /// be dismissed and will log a warning instead.
    ///
    /// The destination's `onDismiss` callback (and any awaiting
    /// `await route(...)` continuation) fires exactly once.
    ///
    /// To hand a value back to a presenter that is awaiting this coordinator,
    /// use ``Coordinatable/dismissCoordinator(returning:)`` — a plain
    /// `dismissCoordinator()` resumes that presenter with `nil`.
    func dismissCoordinator() {
        let logger = Logger(subsystem: "Scaffolding", category: "Dismissal")

        if let parent = parent as? (any TabCoordinatable) {
            // Modal child of a TabCoordinatable → remove from container.modals.
            let selfId = AnyHashable(self.id)
            if parent.anyTabItems.modals.contains(where: {
                guard let cId = $0.coordinatable?.id else { return false }
                return AnyHashable(cId) == selfId
            }) {
                let toRemove = parent.anyTabItems.modals.filter {
                    guard let cId = $0.coordinatable?.id else { return false }
                    return AnyHashable(cId) == selfId
                }
                parent.anyTabItems.modals.removeAll {
                    guard let cId = $0.coordinatable?.id else { return false }
                    return AnyHashable(cId) == selfId
                }
                for destination in toRemove { destination.resolveDismissal() }
                return
            }
            logger.critical("Scaffolding: The coordinator you're trying to dismiss is a TabView child, it will not be dismissed.")
            return
        }

        if let parent = parent as? (any SplitCoordinatable) {
            // Modal child of a SplitCoordinatable → remove from container.modals.
            let selfId = AnyHashable(self.id)
            if parent.anySplitColumns.modals.contains(where: {
                guard let cId = $0.coordinatable?.id else { return false }
                return AnyHashable(cId) == selfId
            }) {
                let toRemove = parent.anySplitColumns.modals.filter {
                    guard let cId = $0.coordinatable?.id else { return false }
                    return AnyHashable(cId) == selfId
                }
                parent.anySplitColumns.modals.removeAll {
                    guard let cId = $0.coordinatable?.id else { return false }
                    return AnyHashable(cId) == selfId
                }
                for destination in toRemove { destination.resolveDismissal() }
                return
            }
            logger.critical("Scaffolding: The coordinator you're trying to dismiss is a split-view column, it will not be dismissed. Replace the column on its SplitCoordinatable instead.")
            return
        }

        if let parent = parent as? (any RootCoordinatable) {
            // Modal child of a RootCoordinatable → remove from container.modals.
            let selfId = AnyHashable(self.id)
            if parent.anyRoot.modals.contains(where: {
                guard let cId = $0.coordinatable?.id else { return false }
                return AnyHashable(cId) == selfId
            }) {
                let toRemove = parent.anyRoot.modals.filter {
                    guard let cId = $0.coordinatable?.id else { return false }
                    return AnyHashable(cId) == selfId
                }
                parent.anyRoot.modals.removeAll {
                    guard let cId = $0.coordinatable?.id else { return false }
                    return AnyHashable(cId) == selfId
                }
                for destination in toRemove { destination.resolveDismissal() }
                if let selfFlow = self as? any FlowCoordinatable {
                    selfFlow.anyStack.destinations.removeAll()
                }
                return
            }
            _resolveOwningDestination()
            parent.parent?.dismissCoordinator()
            // Fallback: if parent.parent was nil or could not dismiss,
            // clean up own pushed destinations to avoid stale navigation state.
            if let selfFlow = self as? any FlowCoordinatable {
                selfFlow.anyStack.destinations.removeAll()
            }
            return
        }

        if let parent = parent as? (any FlowCoordinatable) {
            let selfId = AnyHashable(self.id)

            if let root = parent.anyStack.root,
               let rootCoordinatable = root.coordinatable?.id,
               AnyHashable(rootCoordinatable) == selfId {
                _resolveOwningDestination()
                parent.dismissCoordinator()
                // Fallback: clean up own destinations in case the parent
                // could not be dismissed (e.g. parent chain hits a tab child).
                if let selfFlow = self as? any FlowCoordinatable {
                    selfFlow.anyStack.destinations.removeAll()
                }
                return
            }

            // Remove this coordinator and all destinations pushed after it.
            // Using removeSubrange ensures plain-view destinations on top
            // are also removed (they have no coordinatable to match by ID).
            if let selfIndex = parent.anyStack.destinations.firstIndex(where: {
                guard let coordinatableId = $0.coordinatable?.id else { return false }
                return AnyHashable(coordinatableId) == selfId
            }) {
                let removed = parent.anyStack.destinations[selfIndex...]
                for destination in removed {
                    destination.resolveDismissal()
                }
                parent.anyStack.destinations.removeSubrange(selfIndex...)
            }
        }
    }

    func resolveMeta(_ meta: any DestinationMeta) -> Destinations.Meta? {
        return meta as? Self.Destinations.Meta
    }

    /// Dismisses the most recently presented modal.
    ///
    /// The counterpart of `present(_:as:policy:onDismiss:)` for the presenting
    /// side: removes the top modal from this coordinator and fires its
    /// `onDismiss` callback exactly once, matching an interactive
    /// dismissal. Does nothing when no modal is presented.
    ///
    /// On a ``FlowCoordinatable`` only the modal is removed — destinations
    /// pushed onto the stack stay in place.
    ///
    /// - Returns: `self` for chaining.
    @discardableResult
    func dismissModal() -> Self {
        if let root = self as? any RootCoordinatable {
            guard let modal = root.anyRoot.modals.popLast() else { return self }
            modal.resolveDismissal()
        } else if let tab = self as? any TabCoordinatable {
            guard let modal = tab.anyTabItems.modals.popLast() else { return self }
            modal.resolveDismissal()
        } else if let split = self as? any SplitCoordinatable {
            guard let modal = split.anySplitColumns.modals.popLast() else { return self }
            modal.resolveDismissal()
        } else if let flow = self as? any FlowCoordinatable {
            guard let index = flow.anyStack.destinations.lastIndex(where: {
                $0.pushType == .sheet || $0.pushType == .fullScreenCover
            }) else { return self }
            let modal = flow.anyStack.destinations.remove(at: index)
            modal.resolveDismissal()
        }
        return self
    }

    /// Dismisses every modal presented on this coordinator.
    ///
    /// Like ``dismissModal()`` applied until nothing is presented: each
    /// removed modal fires its `onDismiss` exactly once, and pushed
    /// destinations are untouched. Modals presented by *other*
    /// coordinators deeper in the tree are not affected. Does nothing
    /// when no modal is presented.
    ///
    /// - Returns: `self` for chaining.
    @discardableResult
    func dismissAllModals() -> Self {
        if let root = self as? any RootCoordinatable {
            let removed = root.anyRoot.modals
            root.anyRoot.modals.removeAll()
            for destination in removed.reversed() { destination.resolveDismissal() }
        } else if let tab = self as? any TabCoordinatable {
            let removed = tab.anyTabItems.modals
            tab.anyTabItems.modals.removeAll()
            for destination in removed.reversed() { destination.resolveDismissal() }
        } else if let split = self as? any SplitCoordinatable {
            let removed = split.anySplitColumns.modals
            split.anySplitColumns.modals.removeAll()
            for destination in removed.reversed() { destination.resolveDismissal() }
        } else if let flow = self as? any FlowCoordinatable {
            let isModal: (Destination) -> Bool = {
                $0.pushType == .sheet || $0.pushType == .fullScreenCover
            }
            let removed = flow.anyStack.destinations.filter(isModal)
            flow.anyStack.destinations.removeAll(where: isModal)
            for destination in removed.reversed() { destination.resolveDismissal() }
        }
        return self
    }

    /// Dismisses this coordinator and hands a result back to its presenter.
    ///
    /// The counterpart of the `awaiting:` presentation APIs: the value is
    /// delivered to a suspended
    /// `present(_:as:awaiting:)` call on the presenting side, then the
    /// coordinator is dismissed exactly like ``dismissCoordinator()``.
    ///
    /// ```swift
    /// // Presenting side
    /// let token = await present(.login, awaiting: AuthToken.self)
    ///
    /// // Inside LoginCoordinator
    /// dismissCoordinator(returning: AuthToken(...))
    /// ```
    func dismissCoordinator<Result>(returning result: Result) {
        _owningDestination()?.resolution.result = result
        dismissCoordinator()
    }
}

@MainActor
extension Coordinatable {
    /// Walks the parent's stack/root/tabItems to find the destination
    /// that wraps `self` and fires its dismissal resolution.
    func _resolveOwningDestination() {
        _owningDestination()?.resolveDismissal()
    }

    /// Walks the parent's stack/root/tabItems to find the destination
    /// that wraps `self`.
    func _owningDestination() -> Destination? {
        guard let parent else { return nil }
        let selfId = AnyHashable(self.id)

        let candidates: [Destination] = {
            if let flow = parent as? any FlowCoordinatable {
                var arr: [Destination] = []
                if let r = flow.anyStack.root { arr.append(r) }
                arr.append(contentsOf: flow.anyStack.destinations)
                return arr
            }
            if let root = parent as? any RootCoordinatable {
                var arr: [Destination] = []
                if let r = root.anyRoot.root { arr.append(r) }
                arr.append(contentsOf: root.anyRoot.modals)
                return arr
            }
            if let tab = parent as? any TabCoordinatable {
                var arr: [Destination] = tab.anyTabItems.tabs
                arr.append(contentsOf: tab.anyTabItems.modals)
                return arr
            }
            if let split = parent as? any SplitCoordinatable {
                var arr: [Destination] = []
                if let sidebar = split.anySplitColumns.sidebar { arr.append(sidebar) }
                if let content = split.anySplitColumns.content { arr.append(content) }
                if let detail = split.anySplitColumns.detail { arr.append(detail) }
                arr.append(contentsOf: split.anySplitColumns.modals)
                return arr
            }
            return []
        }()

        return candidates.first(where: {
            guard let cId = $0.coordinatable?.id else { return false }
            return AnyHashable(cId) == selfId
        })
    }
}

@MainActor
extension Coordinatable {
    /// Removes a modal destination hosted directly on this coordinator's
    /// container (Root.modals or TabItems.modals) and fires its dismissal
    /// resolution. No-op for FlowCoordinatable, which manages modals
    /// through its FlowStack.
    func removeContainerModal(id: UUID, type: ModalPresentationType) {
        let target = type.presentationType
        if let root = self as? any RootCoordinatable {
            let toRemove = root.anyRoot.modals.filter { $0.id == id && $0.pushType == target }
            root.anyRoot.modals.removeAll { $0.id == id && $0.pushType == target }
            for destination in toRemove { destination.resolveDismissal() }
        } else if let tab = self as? any TabCoordinatable {
            let toRemove = tab.anyTabItems.modals.filter { $0.id == id && $0.pushType == target }
            tab.anyTabItems.modals.removeAll { $0.id == id && $0.pushType == target }
            for destination in toRemove { destination.resolveDismissal() }
        } else if let split = self as? any SplitCoordinatable {
            let toRemove = split.anySplitColumns.modals.filter { $0.id == id && $0.pushType == target }
            split.anySplitColumns.modals.removeAll { $0.id == id && $0.pushType == target }
            for destination in toRemove { destination.resolveDismissal() }
        }
    }
}

@MainActor
extension Coordinatable {
    func customizeErased(_ view: AnyView) -> AnyView {
        AnyView(customize(view))
    }
}

/// A type that bridges between a coordinator's `Destinations` enum and the
/// concrete ``Destination`` value used at runtime.
///
/// The ``Scaffoldable(injectsCoordinator:codable:)`` macro generates a conforming type automatically —
/// you do not need to implement this protocol yourself.
@MainActor
public protocol Destinationable {
    associatedtype Meta: DestinationMeta
    associatedtype Owner

    /// Metadata that identifies the destination case without its
    /// associated values.
    var meta: Meta { get }

    /// Creates a ``Destination`` for the given coordinator instance.
    @MainActor func value(for instance: Owner) -> Destination
}

@MainActor
extension Destinationable {
    /// Creates a ``Destination`` and records the enum value it was
    /// resolved from, so navigation state can be captured later.
    func resolvedValue(for instance: Owner) -> Destination {
        var destination = value(for: instance)
        destination.setSource(self)
        return destination
    }
}
