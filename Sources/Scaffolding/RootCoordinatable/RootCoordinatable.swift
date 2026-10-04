//
//  RootCoordinatable.swift
//  Scaffolding
//
//  Created by Alexandr Valíček on 26.09.2025.
//

import SwiftUI
import Observation

/// A coordinator that shows one root branch and swaps it as a whole.
///
/// Use it at the top of an app to switch between states such as signed out
/// and signed in. Declare a ``Root`` container and class-body routes:
///
/// ```swift
/// @MainActor @Observable @Scaffoldable
/// final class AppCoordinator: @MainActor RootCoordinatable {
///     var root = Root<AppCoordinator>(root: .login)
///
///     func login() -> any Coordinatable { LoginCoordinator() }
///     func main() -> any Coordinatable { MainTabCoordinator() }
/// }
/// ```
///
/// ``setRoot(_:animation:)`` removes the current branch and builds a fresh
/// one. Modals presented by this coordinator stay until you dismiss them.
/// See <doc:RootSwitching> and <doc:DeepLinking>.
///
/// ## Topics
///
/// ### Changing the Root
///
/// - ``setRoot(_:animation:)``
/// - ``setRoot(_:animation:expecting:)``
/// - ``isRoot(_:)``
/// - ``root``
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
/// ### Transition Animation
///
/// - ``setTransitionAnimation(_:)``
/// - ``setRootTransitionAnimation(_:)``
///
/// ### Type-Erased State
///
/// - ``anyRoot``
///
/// ### Presentation Context
///
/// - ``setPresentedAs(_:)``
///
/// ### Deprecated Compatibility
///
/// - ``present(_:as:policy:onDismiss:)``
/// - ``present(_:as:policy:onDismiss:_:)``
/// - ``present(_:as:policy:onDismiss:expecting:)``
/// - ``presentAndWait(_:as:policy:)``
/// - ``setRoot(_:animation:_:)``
@MainActor
public protocol RootCoordinatable: Coordinatable where ViewType == RootCoordinatableView {
    /// The container holding the current root and this coordinator's modals.
    ///
    /// Seed it with ``Root/init(root:)``; change it through the coordinator.
    var root: Root<Self> { get }

    /// The root container as a read-only, type-erased value.
    var anyRoot: any AnyRoot { get }

    /// Framework access that does not resolve initial destinations.
    var _uninitializedRoot: any AnyRoot { get }
}

@MainActor
public extension RootCoordinatable {
    var _dataId: ObjectIdentifier {
        root.id
    }

    var _uninitializedRoot: any AnyRoot { root }

    var anyRoot: any AnyRoot {
        root.setup(for: self)
        return root
    }

    /// The rendered root coordinator and everything below it.
    ///
    /// Show the top-level coordinator's `view` once, usually in a `WindowGroup`.
    /// Child coordinators render through their parent.
    var view: RootCoordinatableView {
        root.setup(for: self)
        return .init(coordinator: self)
    }

    var parent: (any Coordinatable)? {
        root.parent
    }

    var hasLayerNavigationCoordinatable: Bool {
        root.hasLayerNavigationCoordinator
    }

    func setHasLayerNavigationCoordinatable(_ value: Bool) {
        updateNavigationContext(navigationLayer: value, presentation: inheritedPresentation)
    }

    func setParent(_ parent: any Coordinatable) {
        root.setParent(parent)
    }

    /// Sets the default animation for this coordinator's navigation changes. Pass `nil` to disable it.
    ///
    /// Equivalent to ``setTransitionAnimation(_:)``.
    func setRootTransitionAnimation(_ animation: Animation?) {
        root.setAnimation(animation: animation)
    }
}

@MainActor
public extension RootCoordinatable {
    /// Replaces the root branch with a fresh destination.
    ///
    /// The old branch and its descendants are removed, and their awaiting
    /// callers resume with `nil`. A new destination is built even when the
    /// case is unchanged; check ``isRoot(_:)`` first to keep the current one.
    /// Modals presented by this coordinator stay; call
    /// ``Coordinatable/dismissAllModals()`` to clear them.
    ///
    /// - Parameters:
    ///   - destination: The new root.
    ///   - animation: An animation for this swap. `nil` uses the default.
    /// - Returns: `self`, for chaining.
    @discardableResult
    func setRoot(_ destination: Destinations, animation: Animation? = nil) -> Self {
        guard destination.isAvailable else { return self }
        root.setup(for: self)
        let dest = destination.resolvedValue(for: self)

        root.setRoot(root: dest, animation: animation)

        return self
    }

    /// Returns whether the current root is the given case.
    ///
    /// Compares the case only, not its associated values.
    func isRoot(_ destination: Destinations.Meta) -> Bool {
        guard let rootMeta = _resolvedRoot.root?.meta as? Self.Destinations.Meta else { return false }
        return rootMeta == destination
    }

    /// Deprecated. Use ``setRoot(_:animation:expecting:)`` instead.
    ///
    /// It returns the child directly, so a deep link continues from the result.
    @discardableResult
    @available(*, deprecated, message: "Will be removed in a future update. Use the expecting: overload to access the child coordinator.")
    func setRoot<T: Coordinatable>(
        _ destination: Destinations,
        animation: Animation? = nil,
        _ action: @escaping @MainActor (T) -> Void
    ) -> Self {
        guard destination.isAvailable else { return self }
        root.setup(for: self)
        let dest = destination.resolvedValue(for: self)
        root.setRoot(root: dest, animation: animation)
        if let coordinator = dest.coordinatable as? T {
            action(coordinator)
        }
        return self
    }
}

// MARK: - Typed child resolution

@MainActor
public extension RootCoordinatable {
    /// Replaces the root branch and returns the child as `T`, or `nil` for a
    /// view route or another type. The navigation happens either way.
    ///
    /// Continue a deep link through the returned handle:
    ///
    /// ```swift
    /// let tabs = setRoot(.authenticated, expecting: MainTabCoordinator.self)
    /// let profile = tabs?.selectFirstTab(.profile, expecting: ProfileCoordinator.self)
    /// profile?.route(to: .userDetail(id: userID))
    /// ```
    ///
    /// This always swaps the root; never use it to look up the current child.
    ///
    /// - Parameters:
    ///   - destination: The new root.
    ///   - animation: An animation for this swap. `nil` uses the default.
    ///   - coordinatorType: The child type the route builds.
    /// - Returns: The new child, or `nil`.
    func setRoot<T: Coordinatable>(
        _ destination: Destinations,
        animation: Animation? = nil,
        expecting coordinatorType: T.Type
    ) -> T? {
        guard destination.isAvailable else { return nil }
        root.setup(for: self)
        let dest = destination.resolvedValue(for: self)
        root.setRoot(root: dest, animation: animation)
        return dest.coordinatable as? T
    }
}

@MainActor
public extension RootCoordinatable {
    /// Records how this coordinator is presented.
    ///
    /// The framework calls this when it hosts the coordinator; apps don't need to.
    func setPresentedAs(_ type: PresentationType) {
        inheritPresentation(type)
    }
}

/// The view that renders a ``RootCoordinatable`` and its modals.
///
/// Get it from ``Coordinatable/view``; don't create it directly.
public struct RootCoordinatableView: CoordinatableView {
    private let _coordinator: any RootCoordinatable

    public var coordinator: any Coordinatable {
        _coordinator
    }

    init(coordinator: any RootCoordinatable) {
        self._coordinator = coordinator
    }

    @ViewBuilder
    func coordinatableView() -> some View {
        if let root = _coordinator._resolvedRoot.root {
            wrappedView(root)
                .environmentCoordinatable(coordinator)
                .id(_coordinator._resolvedRoot.root?.id)
        } else {
            EmptyView()
        }
    }

    public var body: some View {
        coordinator.customize(
            AnyView(
                coordinatableView()
            )
        )
        .applyContainerModals(
            destinations: _coordinator._resolvedRoot.modals,
            onDismissSheet: { id in (_coordinator as any Coordinatable).removeContainerModal(id: id, type: .sheet) },
            onDismissFullScreenCover: { id in (_coordinator as any Coordinatable).removeContainerModal(id: id, type: .fullScreenCover) },
            modalContent: wrappedView
        )
        .environmentCoordinatable(coordinator)
    }
}

@MainActor
extension RootCoordinatable {
    var _root: any _MutableRoot { root }
    var _resolvedRoot: any _MutableRoot {
        root.setup(for: self)
        return root
    }
}

@MainActor
public extension RootCoordinatable {
    /// Sets the default animation for this coordinator's navigation changes. Pass `nil` to disable it.
    ///
    /// Applies to root swaps and modal presentations.
    func setTransitionAnimation(_ animation: Animation?) { root.setAnimation(animation: animation) }
}
