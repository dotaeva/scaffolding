//
//  Destination.swift
//  Scaffolding
//
//  Created by Alexandr Valíček on 22.09.2025.
//

import SwiftUI

/// A type that uniquely identifies a destination case without its
/// associated values.
///
/// The ``Scaffoldable(injectsCoordinator:)`` macro generates a conforming `Meta` enum
/// alongside the `Destinations` enum. You can use meta values with
/// methods like ``FlowCoordinatable/popToFirst(_:)`` or
/// ``TabCoordinatable/selectFirstTab(_:)`` to navigate by case name.
@available(iOS 18, macOS 15, *)
@MainActor
public protocol DestinationMeta: Equatable { }

/// Describes how a destination is displayed within a coordinator's
/// navigation hierarchy.
@available(iOS 18, macOS 15, *)
@MainActor
public enum DestinationType {
    /// The destination is the root of the coordinator.
    case root
    /// The destination is pushed onto a `NavigationStack`.
    case push
    /// The destination is presented as a sheet.
    case sheet
    /// The destination is presented as a full-screen cover.
    case fullScreenCover

    var isModal: Bool {
        switch self {
        case .sheet, .fullScreenCover:
            return true
        default: return false
        }
    }

    static func from(presentationType: PresentationType) -> DestinationType {
        return switch presentationType {
        case .push:
                .push
        case .sheet:
                .sheet
        case .fullScreenCover:
                .fullScreenCover
        }
    }
}

/// The presentation style used internally to track how a destination
/// is displayed.
///
/// Routing splits cleanly into push and modal presentation:
/// ``FlowCoordinatable/route(to:onDismiss:)`` always pushes onto the
/// navigation stack, while ``FlowCoordinatable/present(_:as:onDismiss:)``
/// shows a destination as a sheet or full-screen cover. Use
/// ``ModalPresentationType`` at the call site.
@available(iOS 18, macOS 15, *)
@MainActor
public enum PresentationType {
    /// Push the destination onto the navigation stack.
    case push
    /// Present the destination as a sheet.
    case sheet
    /// Present the destination as a full-screen cover.
    case fullScreenCover
}

/// The modal presentation style accepted by
/// ``FlowCoordinatable/present(_:as:onDismiss:)``.
///
/// Modal presentation is restricted to sheet or full-screen cover —
/// pushes are expressed exclusively through
/// ``FlowCoordinatable/route(to:onDismiss:)``.
@available(iOS 18, macOS 15, *)
@MainActor
public enum ModalPresentationType {
    /// Present the destination as a sheet.
    case sheet
    /// Present the destination as a full-screen cover.
    case fullScreenCover

    var presentationType: PresentationType {
        switch self {
        case .sheet: return .sheet
        case .fullScreenCover: return .fullScreenCover
        }
    }
}

// MARK: - Environment Key

// MARK: - Environment Key

@available(iOS 18, macOS 15, *)
private struct DestinationEnvironmentKey: @MainActor EnvironmentKey {
    @MainActor static let defaultValue: Destination = .dummy
}

@available(iOS 18, macOS 15, *)
public extension EnvironmentValues {
    /// The ``Destination`` for the current view in the coordinator hierarchy.
    ///
    /// Scaffolding injects this value automatically so child views can
    /// inspect metadata about the destination they belong to.
    @MainActor
    var destination: Destination {
        get { self[DestinationEnvironmentKey.self] }
        set { self[DestinationEnvironmentKey.self] = newValue }
    }
}

/// A resolved navigation destination that wraps a view or child
/// coordinator together with routing metadata.
///
/// You rarely create `Destination` values yourself — the generated
/// `Destinations` enum produces them via its ``Destinationable/value(for:)``
/// method. Coordinators consume destinations internally when pushing,
/// presenting, or switching roots.
@available(iOS 18, macOS 15, *)
@MainActor
public struct Destination: Identifiable {
    /// Mutable state shared by every value-copy of a destination.
    ///
    /// Holds the user-facing `onDismiss` callback and a single-shot
    /// guard so dismissal fires exactly once even if the destination
    /// is removed through multiple paths (e.g. user-swipe + programmatic
    /// `pop`).
    @MainActor
    final class ResolutionState {
        var onDismiss: (@MainActor () -> Void)?
        var didResolve: Bool = false

        func resolve() {
            guard !didResolve else { return }
            didResolve = true
            onDismiss?()
            onDismiss = nil
        }
    }

    @MainActor
    class CoordinatableCache {
        private let coordinatableFactory: () -> any Coordinatable
        private let viewFactory: (() -> AnyView)?
        private var _cachedCoordinatable: (any Coordinatable)?
        private var _cachedView: AnyView?

        init(_ factory: @escaping () -> any Coordinatable) {
            self.coordinatableFactory = factory
            self.viewFactory = nil
        }

        init<V: View>(_ factory: @escaping () -> (any Coordinatable, V)) {
            self.coordinatableFactory = {
                let (coordinatable, _) = factory()
                return coordinatable
            }
            self.viewFactory = {
                let (_, view) = factory()
                return AnyView(view)
            }
        }

        @available(iOS 18, *)
        @available(macOS 15, *)
        init<V: View>(_ factory: @escaping () -> (any Coordinatable, V, TabRole)) {
            self.coordinatableFactory = {
                let (coordinatable, _, _) = factory()
                return coordinatable
            }
            self.viewFactory = {
                let (_, view, _) = factory()
                return AnyView(view)
            }
        }

        var coordinatable: any Coordinatable {
            if let cached = _cachedCoordinatable {
                return cached
            }
            let instance = coordinatableFactory()
            _cachedCoordinatable = instance
            return instance
        }

        var view: AnyView? {
            guard let viewFactory = viewFactory else { return nil }

            if let cached = _cachedView {
                return cached
            }
            let instance = viewFactory()
            _cachedView = instance
            return instance
        }
    }

    /// A stable identifier for this destination instance.
    public var id: UUID = .init()

    private let _resolution = ResolutionState()
    var resolution: ResolutionState { _resolution }

    private var _view: AnyView?
    private var _tabItem: AnyView?
    var _coordinatable: CoordinatableCache?

    @available(iOS 18, *)
    @available(macOS 15, *)
    var tabRole: TabRole? {
        get { _tabRole as? TabRole }
        set { _tabRole = newValue }
    }

    private var _tabRole: Any?

    var pushType: PresentationType?

    /// How this destination was originally routed (root, push, sheet, or
    /// full-screen cover).
    public var routeType: DestinationType = .root

    /// The effective presentation type, derived from the route's push type.
    public var presentationType: DestinationType {
        switch pushType {
        case .push:
                .push
        case .sheet:
                .sheet
        case .fullScreenCover:
                .fullScreenCover
        case nil:
                .root
        }
    }

    /// Metadata identifying which destination case this value represents.
    public let meta: any DestinationMeta
    var parent: any Coordinatable

    /// The user-facing dismissal callback, stored on the shared
    /// resolution state so a value-copy of the destination still
    /// reflects updates made to the original.
    var onDismiss: (() -> Void)? {
        guard let cb = _resolution.onDismiss else { return nil }
        return { cb() }
    }

    /// The child coordinator backing this destination, if any.
    ///
    /// Returns `nil` when the destination wraps a plain view. Useful in
    /// hooks like ``TabCoordinatable/tabReselected(_:)`` to act on the
    /// tab's coordinator — for example, popping its flow back to root.
    public var coordinatable: (any Coordinatable)? {
        return _coordinatable?.coordinatable
    }

    // MARK: - Environment-Injected Accessors

    /// Returns the view with Destination injected into environment
    var view: AnyView? {
        guard let v = _view else { return nil }
        return AnyView(v.environment(\.destination, self))
    }

    /// Returns the tab item view with Destination injected into environment
    var tabItem: AnyView? {
        guard let item = _tabItem ?? _coordinatable?.view else { return nil }
        return AnyView(item.environment(\.destination, self))
    }

    // MARK: - Basic Initializers

    /// Creates a destination that displays a plain SwiftUI view.
    public init<V: View>(
        _ value: V,
        meta: any DestinationMeta,
        parent: any Coordinatable
    ) {
        self._view = AnyView(value)
        self.meta = meta
        self.parent = parent
    }

    /// Creates a destination backed by a child coordinator.
    public init(
        _ factory: @escaping () -> any Coordinatable,
        meta: any DestinationMeta,
        parent: any Coordinatable
    ) {
        self._coordinatable = CoordinatableCache(factory)
        self.meta = meta
        self.parent = parent
    }

    /// Creates a destination with a child coordinator and a custom tab
    /// item view.
    public init<V: View>(
        _ factory: @escaping () -> (any Coordinatable, V),
        meta: any DestinationMeta,
        parent: any Coordinatable
    ) {
        self._coordinatable = CoordinatableCache(factory)
        self.meta = meta
        self.parent = parent
    }

    /// Creates a destination with a content view and a tab item view.
    public init<V: View, T: View>(
        _ factory: @escaping () -> (V, T),
        meta: any DestinationMeta,
        parent: any Coordinatable
    ) {
        let (v, t) = factory()

        self._view = AnyView(v)
        self.meta = meta
        self.parent = parent
        self._tabItem = AnyView(t)
    }

    // MARK: - TabRole Initializers

    /// Creates a destination with a content view and a `TabRole`.
    @available(iOS 18, *)
    @available(macOS 15, *)
    public init<V: View>(
        _ factory: @escaping () -> (V, TabRole),
        meta: any DestinationMeta,
        parent: any Coordinatable
    ) {
        let (v, role) = factory()

        self._view = AnyView(v)
        self.meta = meta
        self.parent = parent
        self._tabRole = role
    }

    /// Creates a destination with a child coordinator and a `TabRole`.
    @available(iOS 18, *)
    @available(macOS 15, *)
    public init(
        _ factory: @escaping () -> (any Coordinatable, TabRole),
        meta: any DestinationMeta,
        parent: any Coordinatable
    ) {
        let result = factory()
        let role = result.1

        self._coordinatable = CoordinatableCache({ result.0 })
        self.meta = meta
        self.parent = parent
        self._tabRole = role
    }

    /// Creates a destination with a content view, a tab item view, and a
    /// `TabRole`.
    @available(iOS 18, *)
    @available(macOS 15, *)
    public init<V: View, T: View>(
        _ factory: @escaping () -> (V, T, TabRole),
        meta: any DestinationMeta,
        parent: any Coordinatable
    ) {
        let (v, t, role) = factory()

        self._view = AnyView(v)
        self.meta = meta
        self.parent = parent
        self._tabItem = AnyView(t)
        self._tabRole = role
    }

    /// Creates a destination with a child coordinator, a tab item view,
    /// and a `TabRole`.
    @available(iOS 18, *)
    @available(macOS 15, *)
    public init<V: View>(
        _ factory: @escaping () -> (any Coordinatable, V, TabRole),
        meta: any DestinationMeta,
        parent: any Coordinatable
    ) {
        let result = factory()

        self._coordinatable = CoordinatableCache(factory)
        self.meta = meta
        self.parent = parent
        self._tabRole = result.2
    }

    // MARK: - Mutating Methods

    /// Stores the dismissal callback on the shared resolution state.
    ///
    /// Non-mutating: writes to a reference-typed slot, so value-copies of
    /// the destination observe the same callback.
    func setOnDismiss(_ value: @escaping @MainActor () -> Void) {
        _resolution.onDismiss = value
    }

    mutating func setPushType(_ value: PresentationType) {
        pushType = value
    }

    mutating func setRouteType(_ value: DestinationType) {
        routeType = value
    }

    // MARK: - Resolution

    /// Fires the destination's `onDismiss` callback exactly once.
    /// Called from every removal site: pop, popToRoot, popToFirst/Last,
    /// setRoot, dismissCoordinator, removeModalDestination, sheet swipe.
    func resolveDismissal() {
        _resolution.resolve()
    }
}

@available(iOS 18, macOS 15, *)
@MainActor
extension Destination: @MainActor Equatable, @MainActor Hashable {
    public static func ==(lhs: Destination, rhs: Destination) -> Bool {
        return lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
