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
/// The ``Scaffoldable(injectsCoordinator:codable:)`` macro generates a conforming `Meta` enum
/// alongside the `Destinations` enum. You can use meta values with
/// methods like ``FlowCoordinatable/popToFirst(_:)`` or
/// ``TabCoordinatable/selectFirstTab(_:)`` to navigate by case name.
@MainActor
public protocol DestinationMeta: Equatable { }

/// Describes how a destination is displayed within a coordinator's
/// navigation hierarchy.
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

    /// Whether the destination is presented modally
    /// (`.sheet` or `.fullScreenCover`).
    public var isModal: Bool {
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
/// ``FlowCoordinatable/route(to:policy:onDismiss:)`` always pushes onto the
/// navigation stack, while ``FlowCoordinatable/present(_:as:policy:onDismiss:)``
/// shows a destination as a sheet or full-screen cover. Use
/// ``ModalPresentationType`` at the call site.
@MainActor
public enum PresentationType {
    /// Push the destination onto the navigation stack.
    case push
    /// Present the destination as a sheet.
    case sheet
    /// Present the destination as a full-screen cover.
    case fullScreenCover
}

/// Controls whether a navigation request is applied when its destination
/// is already showing.
///
/// Pass `.distinct` to guard against double-taps and repeated requests:
/// a push is skipped when the same destination case is already on top of
/// the stack, and a modal presentation is skipped when the same
/// destination case is already presented.
///
/// The comparison uses the destination's ``DestinationMeta`` (the case
/// name), not its associated values — two pushes of the same case with
/// different arguments still count as duplicates. Use `.always` (the
/// default) when consecutive same-case destinations are intentional,
/// e.g. recursive folder navigation.
public enum RoutePolicy: Sendable {
    /// Always apply the navigation request.
    case always
    /// Skip the request when the same destination case is already on top
    /// (pushes) or already presented (modals).
    case distinct
}

/// Presenter-side configuration for a sheet presentation.
///
/// Carried by ``ModalPresentationType/sheet(detents:dragIndicator:interactiveDismissDisabled:)``
/// and applied by the framework to the presented content. This lets the
/// *presenter* decide how a destination is shown — the same destination
/// can be a medium sheet from one place and a full-height sheet from
/// another, without the destination view knowing.
public struct SheetConfiguration: Equatable, Sendable {
    /// The detents available to the sheet. Empty means the system default.
    public var detents: Set<PresentationDetent>
    /// Visibility of the drag indicator at the top of the sheet.
    public var dragIndicator: Visibility
    /// Whether interactive (swipe-down) dismissal is disabled.
    public var interactiveDismissDisabled: Bool

    public init(
        detents: Set<PresentationDetent> = [],
        dragIndicator: Visibility = .automatic,
        interactiveDismissDisabled: Bool = false
    ) {
        self.detents = detents
        self.dragIndicator = dragIndicator
        self.interactiveDismissDisabled = interactiveDismissDisabled
    }
}

/// The modal presentation style accepted by
/// ``FlowCoordinatable/present(_:as:policy:onDismiss:)``.
///
/// Modal presentation is restricted to sheet or full-screen cover —
/// pushes are expressed exclusively through
/// ``FlowCoordinatable/route(to:policy:onDismiss:)``.
///
/// Use the plain ``sheet`` / ``fullScreenCover`` values, or configure the
/// sheet from the presenting side:
///
/// ```swift
/// coordinator.present(.settings, as: .sheet(detents: [.medium, .large]))
/// ```
@MainActor
public struct ModalPresentationType: Equatable {
    enum Kind: Equatable {
        case sheet
        case fullScreenCover
    }

    let kind: Kind
    let configuration: SheetConfiguration?

    /// Present the destination as a sheet with system-default behavior.
    public static let sheet = ModalPresentationType(kind: .sheet, configuration: nil)

    /// Present the destination as a full-screen cover.
    public static let fullScreenCover = ModalPresentationType(kind: .fullScreenCover, configuration: nil)

    /// Present the destination as a sheet configured by the presenter.
    ///
    /// - Parameters:
    ///   - detents: The detents available to the sheet. Empty means the
    ///     system default.
    ///   - dragIndicator: Visibility of the sheet's drag indicator.
    ///   - interactiveDismissDisabled: Disables swipe-down dismissal when
    ///     `true`. Programmatic dismissal keeps working.
    public static func sheet(
        detents: Set<PresentationDetent> = [],
        dragIndicator: Visibility = .automatic,
        interactiveDismissDisabled: Bool = false
    ) -> ModalPresentationType {
        ModalPresentationType(
            kind: .sheet,
            configuration: SheetConfiguration(
                detents: detents,
                dragIndicator: dragIndicator,
                interactiveDismissDisabled: interactiveDismissDisabled
            )
        )
    }

    var presentationType: PresentationType {
        switch kind {
        case .sheet: return .sheet
        case .fullScreenCover: return .fullScreenCover
        }
    }
}

// MARK: - Environment Key

// MARK: - Environment Key

private struct DestinationEnvironmentKey: @MainActor EnvironmentKey {
    @MainActor static let defaultValue: Destination = .dummy
}

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

        /// A value handed back by ``Coordinatable/dismissCoordinator(returning:)``,
        /// consumed by the `awaiting:` presentation APIs.
        var result: Any?

        private var continuations: [CheckedContinuation<Void, Never>] = []

        func resolve() {
            guard !didResolve else { return }
            didResolve = true
            onDismiss?()
            onDismiss = nil
            let pending = continuations
            continuations = []
            for continuation in pending {
                continuation.resume()
            }
        }

        /// Suspends until ``resolve()`` fires. Returns immediately when the
        /// destination has already been resolved.
        func awaitResolution() async {
            guard !didResolve else { return }
            await withCheckedContinuation { continuation in
                continuations.append(continuation)
            }
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

        /// The already-created coordinator, without materialising one.
        var materializedCoordinatable: (any Coordinatable)? {
            _cachedCoordinatable
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

    /// The original `Destinations` enum value this destination was resolved
    /// from, when known. Used for navigation-state capture.
    private var _source: Any?
    var source: Any? { _source }

    /// Presenter-side sheet configuration, when the destination was
    /// presented with a configured ``ModalPresentationType``.
    public internal(set) var modalConfiguration: SheetConfiguration?

    /// The badge shown on this destination's tab item, if any.
    public internal(set) var badge: String?

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

    var coordinatable: (any Coordinatable)? {
        return _coordinatable?.coordinatable
    }

    /// Whether this destination is backed by a child coordinator, without
    /// forcing its creation.
    var hasCoordinatable: Bool {
        _coordinatable != nil
    }

    /// The child coordinator if it has already been created; never
    /// materialises one.
    var materializedCoordinatable: (any Coordinatable)? {
        _coordinatable?.materializedCoordinatable
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

    mutating func setSource(_ value: Any) {
        _source = value
    }

    mutating func setModalConfiguration(_ value: SheetConfiguration?) {
        modalConfiguration = value
    }

    // MARK: - Resolution

    /// Fires the destination's `onDismiss` callback exactly once.
    /// Called from every removal site: pop, popToRoot, popToFirst/Last,
    /// setRoot, dismissCoordinator, removeModalDestination, sheet swipe.
    func resolveDismissal() {
        _resolution.resolve()
    }
}

@MainActor
extension Destination: @MainActor Equatable, @MainActor Hashable {
    public static func ==(lhs: Destination, rhs: Destination) -> Bool {
        return lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
