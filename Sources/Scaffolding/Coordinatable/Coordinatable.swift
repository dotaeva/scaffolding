//
//  Coordinatable.swift
//  Scaffolding
//
//  Created by Alexandr Valíček on 22.09.2025.
//

import SwiftUI
import os.log

/// The interface every coordinator shares.
///
/// Don't adopt `Coordinatable` directly. Adopt ``FlowCoordinatable``,
/// ``RootCoordinatable``, ``TabCoordinatable``, or ``SplitCoordinatable``;
/// each inherits the modal presentation, dismissal, hierarchy, and
/// restoration API below. Generic helpers constrained to `C: Coordinatable`
/// can use it too.
///
/// Add `expecting:` to `present` to get the child immediately, `awaiting:` to
/// wait for its result, or both to configure the child before waiting. See
/// <doc:ModalsAndResults> and <doc:Essentials>.
///
/// ## Topics
///
/// ### Presenting and Receiving Results
///
/// - ``present(_:as:policy:)``
/// - ``present(_:as:policy:expecting:)``
/// - ``present(_:as:policy:awaiting:)``
/// - ``present(_:as:policy:expecting:awaiting:)``
///
/// ### Closing Flows and Modals
///
/// - ``dismissCoordinator()``
/// - ``dismissCoordinator(returning:)``
/// - ``dismissPresentedModal()``
/// - ``cancelPendingModals()``
/// - ``dismissModal()``
/// - ``dismissAllModals()``
/// - ``isPresentingModal``
/// - ``pendingModalCount``
///
/// ### Rendering and Shared Appearance
///
/// - ``view``
/// - ``customize(_:)``
///
/// ### Hierarchy and Presentation
///
/// - ``parent``
/// - ``routeType``
/// - ``ancestor(ofType:)``
/// - ``hierarchyRoot``
/// - ``hierarchySnapshot()``
/// - ``debugHierarchy()``
///
/// ### Capturing and Restoring Navigation
///
/// - ``captureNavigationState()``
/// - ``captureNavigationState(version:)``
/// - ``captureNavigationStateWithReport(version:)``
/// - ``restoreNavigationState(from:mode:)``
/// - ``restoreNavigationStateWithReport(from:mode:migrate:)``
/// - ``restoreNavigationState(from:)``
///
/// ### Coordinator Types
///
/// - ``Destinations``
/// - ``ViewType``
/// - ``CustomizeContentView``
///
/// ### Framework Integration
///
/// - ``hasLayerNavigationCoordinatable``
/// - ``setHasLayerNavigationCoordinatable(_:)``
/// - ``setParent(_:)``
/// - ``resolveMeta(_:)``
@MainActor
public protocol Coordinatable: AnyObject, Identifiable {
    /// The route enum that ``Scaffoldable(injectsCoordinator:codable:)``
    /// generates from the class body's route functions.
    associatedtype Destinations: Destinationable where Destinations.Owner == Self
    /// The view that renders this coordinator.
    associatedtype ViewType: View
    /// The view that ``customize(_:)`` returns.
    associatedtype CustomizeContentView: View

    var _dataId: ObjectIdentifier { get }
    nonisolated var _injectsCoordinator: Bool { get }
    /// The coordinator that hosts this one, or `nil` at the top level.
    var parent: (any Coordinatable)? { get }
    /// Whether this coordinator renders inside a `NavigationStack` owned by an
    /// ancestor flow, as a pushed child or a flow's root.
    ///
    /// The framework maintains this value.
    var hasLayerNavigationCoordinatable: Bool { get }
    /// The SwiftUI view that renders this coordinator and everything it owns.
    ///
    /// Mount the top-level coordinator's `view` once, in your scene. Don't wrap
    /// it or any route in a navigation container. See <doc:Essentials>.
    var view: ViewType { get }
    /// Updates ``hasLayerNavigationCoordinatable``. Framework use only.
    func setHasLayerNavigationCoordinatable(_ value: Bool)
    /// Attaches this coordinator to its host. Framework use only; navigation
    /// methods attach children for you.
    func setParent(_ value: any Coordinatable)

    /// Whether this coordinator owns a modal request, visible or queued.
    var isPresentingModal: Bool { get }

    /// Presents a destination as a sheet or full-screen cover.
    ///
    /// The request joins this coordinator's presentation host, which shows one
    /// request at a time; later requests wait. A presented child coordinator is
    /// a new host. A route unavailable on the current OS is skipped. See
    /// <doc:ModalsAndResults>.
    ///
    /// - Parameters:
    ///   - destination: The route to present.
    ///   - type: `.sheet` (the default) or `.fullScreenCover`. On macOS a cover
    ///     renders as a sheet.
    ///   - policy: `.distinct` skips the request when this coordinator already
    ///     has one for the same case, visible or queued. Associated values are
    ///     ignored.
    /// - Returns: `self`, for chaining.
    @discardableResult
    func present(_ destination: Destinations, as type: ModalPresentationType, policy: RoutePolicy) -> Self

    /// Presents a destination and returns the child as `T`, or `nil` for a view
    /// route or another type. The navigation happens either way.
    ///
    /// ```swift
    /// present(.settings, expecting: SettingsCoordinator.self)?.route(to: .account)
    /// ```
    ///
    /// A skipped request — `.distinct` or an unavailable route — presents
    /// nothing and returns `nil`. To also wait for a result, use
    /// ``present(_:as:policy:expecting:awaiting:)``.
    func present<T: Coordinatable>(_ destination: Destinations, as type: ModalPresentationType, policy: RoutePolicy, expecting coordinatorType: T.Type) -> T?

    /// Presents a destination and suspends until it leaves, returning its result.
    ///
    /// ```swift
    /// if let item = await present(.picker, awaiting: Item.self) { apply(item) }
    /// _ = await present(.help, awaiting: Void.self)  // wait only
    /// ```
    ///
    /// A child coordinator returns a value with ``dismissCoordinator(returning:)``;
    /// a view route returns one with ``Destination/dismiss(returning:)``. The call
    /// returns `nil` when the destination closes without a value, the value has
    /// another type, or the request is skipped. `Void.self` waits for removal
    /// only; it doesn't prove the flow succeeded.
    ///
    /// Cancelling the waiting task returns `nil` and leaves the modal open. A
    /// task that is already cancelled presents nothing.
    func present<Result>(_ destination: Destinations, as type: ModalPresentationType, policy: RoutePolicy, awaiting resultType: Result.Type) async -> Result?

    /// Presents a destination and immediately returns its child and a closure
    /// that awaits its result.
    ///
    /// ```swift
    /// let (picker, result) = present(
    ///     .picker, expecting: PickerCoordinator.self, awaiting: Item.self
    /// )
    /// picker?.route(to: .favorites)
    /// let item = await result()
    /// ```
    ///
    /// The call doesn't suspend; only `result()` does.
    ///
    /// - `coordinator` is `nil` for a view route or another type; `result()`
    ///   still works.
    /// - A skipped request, or a call from a cancelled task, presents nothing
    ///   and returns a `nil` coordinator and a `result()` that returns `nil`.
    /// - `result()` observes this destination even after it closes; calling it
    ///   again returns the same value.
    /// - Cancelling a task running `result()` releases only that wait.
    func present<T: Coordinatable, Result>(_ destination: Destinations, as type: ModalPresentationType, policy: RoutePolicy, expecting coordinatorType: T.Type, awaiting resultType: Result.Type) -> (coordinator: T?, result: @MainActor () async -> Result?)

    /// Wraps everything this coordinator renders.
    ///
    /// Implement it in an extension to apply shared chrome — tint, toolbars,
    /// overlays, presentation modifiers — to the coordinator's container. In
    /// the class body, mark it ``ScaffoldingIgnored()`` so the macro doesn't
    /// treat it as a route. Never add a navigation container here.
    ///
    /// - Parameter view: The coordinator's rendered content.
    /// - Returns: The wrapped content.
    func customize(_ view: AnyView) -> CustomizeContentView

    /// Framework hook behind ``captureNavigationState()``. Don't implement or
    /// call it.
    func _captureNavigationStateNode() -> NavigationStateNode?

    /// Framework hook behind ``restoreNavigationState(from:mode:)``. Don't
    /// implement or call it.
    func _restoreNavigationStateNode(_ node: NavigationStateNode)
}

@MainActor
public extension Coordinatable {
    /// Whether managed views receive this coordinator through `@Environment`.
    ///
    /// `@Scaffoldable(injectsCoordinator: false)` makes it `false`.
    nonisolated var _injectsCoordinator: Bool { true }

    /// Returns the content unchanged.
    ///
    /// Implement `customize(_:)` in an extension to wrap everything this
    /// coordinator renders.
    func customize(_ view: AnyView) -> some View {
        view
    }

    /// Removes this coordinator from its host.
    ///
    /// | Where this coordinator is | Effect |
    /// |---|---|
    /// | Pushed | Removes it and everything pushed above it |
    /// | Presented | Closes that presentation |
    /// | Root of a flow or root coordinator | Dismisses that host instead |
    /// | Tab or split column | Nothing; remove the tab or replace the column |
    /// | Top level | Nothing |
    ///
    /// Waiters on the removed route resume with `nil`; use
    /// ``dismissCoordinator(returning:)`` to deliver a value. Removed
    /// descendants resolve once, deepest and topmost first, after the branch
    /// is detached.
    func dismissCoordinator() {
        guard let parent else { return }
        let matches: (Destination) -> Bool = { $0.materializedCoordinatable === self }

        if let flow = parent as? any FlowCoordinatable {
            let stack = flow._stack
            if let root = stack.root, matches(root) {
                flow.dismissCoordinator()
            } else if let index = stack.destinations.firstIndex(where: matches) {
                if stack.destinations[index].routeType.isModal {
                    parent.removeOwnModals(where: matches)
                    return
                }
                let removed = Array(stack.destinations[index...])
                withScaffoldingAnimation(stack.animation) { stack.destinations.removeSubrange(index...) }
                resolveDismissals(removed)
            }
        } else if let root = parent as? any RootCoordinatable {
            let container = root._root
            if let index = container.modals.firstIndex(where: matches) {
                let removedID = container.modals[index].id
                parent.removeOwnModals { $0.id == removedID }
            } else if let destination = container.root, matches(destination) {
                root.dismissCoordinator()
            }
        } else if let tab = parent as? any TabCoordinatable {
            let container = tab._tabItems
            if let index = container.modals.firstIndex(where: matches) {
                let removedID = container.modals[index].id
                parent.removeOwnModals { $0.id == removedID }
            } else {
                Logger(subsystem: "Scaffolding", category: "Dismissal")
                    .warning("Tab children are structural. Remove or replace the tab on its owner.")
            }
        } else if let split = parent as? any SplitCoordinatable {
            let container = split._columns
            if let index = container.modals.firstIndex(where: matches) {
                let removedID = container.modals[index].id
                parent.removeOwnModals { $0.id == removedID }
            } else {
                Logger(subsystem: "Scaffolding", category: "Dismissal")
                    .warning("Split columns are structural. Replace the column on its owner.")
            }
        }
    }

    /// Casts type-erased route metadata to this coordinator's
    /// `Destinations.Meta`, or returns `nil` for another coordinator's case.
    func resolveMeta(_ meta: any DestinationMeta) -> Destinations.Meta? {
        return meta as? Self.Destinations.Meta
    }

    /// Removes this coordinator's most recent modal request, even a queued one.
    ///
    /// With A visible and B queued, this removes B; use
    /// ``dismissPresentedModal()`` to close A. The removed request's waiters
    /// resume with `nil`. Pushed screens stay.
    ///
    /// - Returns: `self`, for chaining.
    @discardableResult
    func dismissModal() -> Self {
        guard let last = ownModalDestinations.last else { return self }
        removeOwnModals { $0.id == last.id }
        return self
    }

    /// Removes every modal request this coordinator owns, visible or queued.
    ///
    /// Each removed branch's waiters resume with `nil`. Pushed screens stay, and
    /// so do requests owned by other coordinators, such as a pushed child flow.
    ///
    /// - Returns: `self`, for chaining.
    @discardableResult
    func dismissAllModals() -> Self {
        removeOwnModals { _ in true }
        return self
    }

    /// Removes this coordinator from its host and returns a value to the caller
    /// awaiting it.
    ///
    /// ```swift
    /// // Presenter
    /// let token = await present(.login, awaiting: AuthToken.self)
    ///
    /// // Inside LoginCoordinator
    /// dismissCoordinator(returning: token)
    /// ```
    ///
    /// Removal follows ``dismissCoordinator()``. When this coordinator is the
    /// root of a flow or root coordinator, the value goes to the route that
    /// actually leaves. A caller awaiting another type receives `nil`.
    func dismissCoordinator<Result>(returning result: Result) {
        // Structural roots dismiss through their wrappers. Deliver to the
        // route that is actually leaving its presenter, not an inner root.
        var subject: any Coordinatable = self
        while let destination = subject._owningDestination(), let owner = subject.parent {
            let isFlowRoot = (owner as? any FlowCoordinatable)?._stack.root?.id == destination.id
            let isRoot = (owner as? any RootCoordinatable)?._root.root?.id == destination.id
            if isFlowRoot || isRoot {
                subject = owner
                continue
            }
            if destination.routeType != .root {
                destination.resolution.result = result
            }
            break
        }
        dismissCoordinator()
    }
}

@MainActor
extension Coordinatable {
    /// Walks the parent's stack/root/tabItems to find the destination
    /// that wraps `self`.
    func _owningDestination() -> Destination? {
        guard let parent else { return nil }
        let selfId = AnyHashable(self.id)

        let candidates: [Destination] = {
            if let flow = parent as? any FlowCoordinatable {
                var arr: [Destination] = []
                if let r = flow._stack.root { arr.append(r) }
                arr.append(contentsOf: flow._stack.destinations)
                return arr
            }
            if let root = parent as? any RootCoordinatable {
                var arr: [Destination] = []
                if let r = root._root.root { arr.append(r) }
                arr.append(contentsOf: root._root.modals)
                return arr
            }
            if let tab = parent as? any TabCoordinatable {
                var arr: [Destination] = tab._tabItems.tabs
                arr.append(contentsOf: tab._tabItems.modals)
                return arr
            }
            if let split = parent as? any SplitCoordinatable {
                var arr: [Destination] = []
                if let sidebar = split._columns.sidebar { arr.append(sidebar) }
                if let content = split._columns.content { arr.append(content) }
                if let detail = split._columns.detail { arr.append(detail) }
                arr.append(contentsOf: split._columns.modals)
                return arr
            }
            return []
        }()

        return candidates.first(where: {
            guard let cId = $0.materializedCoordinatable?.id else { return false }
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
        guard !(self is any FlowCoordinatable) else { return }
        removeOwnModals { $0.id == id && $0.pushType == type.presentationType }
    }
}

@MainActor
extension Coordinatable {
    func customizeErased(_ view: AnyView) -> AnyView {
        AnyView(customize(view))
    }
}

/// The interface of a generated `Destinations` enum.
///
/// ``Scaffoldable(injectsCoordinator:codable:)`` generates the conformance.
/// Don't adopt it yourself.
@MainActor
public protocol Destinationable {
    /// The payload-free case identity, generated as `Destinations.Meta`.
    associatedtype Meta: DestinationMeta
    /// The coordinator that declares these routes.
    associatedtype Owner

    /// This case without its associated values.
    var meta: Meta { get }

    /// Whether the current OS supports this route.
    ///
    /// Routes marked `@available` report it at runtime. Presentation skips an
    /// unavailable route; restoration reports and skips it.
    var isAvailable: Bool { get }

    /// Builds the ``Destination`` for this case, owned by `instance`.
    @MainActor func value(for instance: Owner) -> Destination
}

@MainActor
public extension Destinationable {
    var isAvailable: Bool { true }
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
