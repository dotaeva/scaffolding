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
    func view() -> ViewType
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
}

@MainActor
public extension Coordinatable {
    func customize(_ view: AnyView) -> some View {
        view
    }

    /// Dismisses this coordinator from its parent's navigation hierarchy.
    ///
    /// If the coordinator is the root of a ``FlowCoordinatable`` stack, the
    /// entire flow is dismissed. If it lives inside a stack as a pushed
    /// destination, only that destination is removed. Tab children cannot
    /// be dismissed and will log a warning instead.
    func dismissCoordinator() {
        let logger = Logger(subsystem: "Scaffolding", category: "Dismissal")

        if parent is (any TabCoordinatable) {
            logger.critical("Scaffolding: The coordinator you're trying to dismiss is a TabView child, it will not be dismissed.")
            return
        }

        if let parent = parent as? (any RootCoordinatable) {
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
                parent.anyStack.destinations.removeSubrange(selfIndex...)
            }
        }
    }

    func resolveMeta(_ meta: any DestinationMeta) -> Destinations.Meta? {
        return meta as? Self.Destinations.Meta
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
/// The ``Scaffoldable()`` macro generates a conforming type automatically —
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
