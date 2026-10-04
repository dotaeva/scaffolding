//
//  Destination.swift
//  Scaffolding
//
//  Created by Alexandr Valíček on 22.09.2025.
//

import SwiftUI

/// A route case without its associated values.
///
/// ``Scaffoldable(injectsCoordinator:codable:)`` generates a conforming
/// `Destinations.Meta` enum. Pass its cases to queries and case-based
/// navigation such as ``FlowCoordinatable/isInStack(_:)``,
/// ``FlowCoordinatable/popToFirst(_:)``, and
/// ``TabCoordinatable/selectFirstTab(_:)``. `.detail(id: 1)` and
/// `.detail(id: 2)` share the meta case `.detail`.
@MainActor
public protocol DestinationMeta: Equatable { }

/// How a destination is shown: as a root, pushed, or presented.
///
/// ``Destination/routeType`` and ``Coordinatable/routeType`` report how a
/// screen or coordinator entered its owner. ``Destination/presentationType``
/// reports how a screen appears, including a presentation it inherits.
@MainActor
public enum DestinationType {
    /// A structural destination: its owner's root, a tab, or a split column.
    case root
    /// Pushed onto a navigation stack.
    case push
    /// Presented as a sheet.
    case sheet
    /// Presented as a full-screen cover. On macOS it renders as a sheet.
    case fullScreenCover

    /// Whether this is `.sheet` or `.fullScreenCover`.
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

/// How the framework attaches a destination: pushed or presented.
///
/// You don't pass this at call sites. Push with
/// ``FlowCoordinatable/route(to:policy:)``; present with
/// ``Coordinatable/present(_:as:policy:)`` and a ``ModalPresentationType``.
@MainActor
public enum PresentationType {
    /// Pushed onto a navigation stack.
    case push
    /// Presented as a sheet.
    case sheet
    /// Presented as a full-screen cover.
    case fullScreenCover
}

/// Whether a navigation request applies when its case is already showing.
///
/// Use `.distinct` to absorb double taps. It compares cases only:
/// `.detail(id: 1)` matches `.detail(id: 2)`. Guard record identity with
/// your own state. See <doc:Essentials#Know-the-surprising-semantics>.
public enum RoutePolicy: Sendable {
    /// Apply every request. The default; use it when repeating a case is
    /// intentional, such as nested folders.
    case always
    /// Skip the request when its case already occupies the target: the top
    /// of the stack for a push, an existing request (visible or queued) for a
    /// presentation, or the column for a split setter.
    case distinct
}

/// Deprecated. Use SwiftUI's presentation modifiers on the presented content
/// instead.
///
/// Apply `presentationDetents`, `presentationDragIndicator`, and
/// `interactiveDismissDisabled` to the presented view, or to a child
/// coordinator in its `customize(_:)`.
@available(*, deprecated, message: "Apply SwiftUI presentation modifiers to the presented view, or in the presented coordinator's customize(_:), instead.")
public struct SheetConfiguration: Equatable, Sendable {
    /// The sheet's detents. Empty uses the system default.
    public var detents: Set<PresentationDetent>
    /// The drag indicator's visibility.
    public var dragIndicator: Visibility
    /// Whether swipe-to-dismiss is disabled.
    public var interactiveDismissDisabled: Bool

    /// Creates a sheet configuration.
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

/// Internal storage for the deprecated presenter-side configuration. Keep the
/// compatibility type at the API boundary so normal routing builds warning-free.
struct LegacySheetConfiguration: Equatable, Sendable {
    var detents: Set<PresentationDetent>
    var dragIndicator: Visibility
    var interactiveDismissDisabled: Bool
}

/// The modal style for ``Coordinatable/present(_:as:policy:)``: a sheet or a
/// full-screen cover.
///
/// ```swift
/// coordinator.present(.player, as: .fullScreenCover)
/// ```
///
/// Configure sizing and dismissal with SwiftUI modifiers on the presented
/// content; see <doc:ModalsAndResults#Configure-presented-content>. To push,
/// use ``FlowCoordinatable/route(to:policy:)``.
///
/// ## Topics
///
/// ### Presentation Styles
///
/// - ``sheet``
/// - ``fullScreenCover``
///
/// ### Deprecated Compatibility
///
/// - ``sheet(detents:dragIndicator:interactiveDismissDisabled:)``
@MainActor
public struct ModalPresentationType: Equatable {
    enum Kind: Equatable {
        case sheet
        case fullScreenCover
    }

    let kind: Kind
    let configuration: LegacySheetConfiguration?

    /// A sheet. The default for `present`.
    public static let sheet = ModalPresentationType(kind: .sheet, configuration: nil)

    /// A full-screen cover. On macOS it renders as a sheet but still reports
    /// `.fullScreenCover`.
    public static let fullScreenCover = ModalPresentationType(kind: .fullScreenCover, configuration: nil)

    /// Deprecated. Use ``sheet`` instead.
    ///
    /// Apply `presentationDetents`, `presentationDragIndicator`, and
    /// `interactiveDismissDisabled` to the presented content.
    ///
    /// - Parameters:
    ///   - detents: The sheet's detents. Empty uses the system default.
    ///   - dragIndicator: The drag indicator's visibility.
    ///   - interactiveDismissDisabled: Whether swipe-to-dismiss is disabled.
    ///     Programmatic dismissal still works.
    @available(*, deprecated, message: "Use .sheet and apply presentationDetents(_:), presentationDragIndicator(_:), and interactiveDismissDisabled(_:) to the presented view or the presented coordinator's customize(_:).")
    public static func sheet(
        detents: Set<PresentationDetent> = [],
        dragIndicator: Visibility = .automatic,
        interactiveDismissDisabled: Bool = false
    ) -> ModalPresentationType {
        ModalPresentationType(
            kind: .sheet,
            configuration: LegacySheetConfiguration(
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

private struct DestinationEnvironmentKey: @MainActor EnvironmentKey {
    @MainActor static let defaultValue: Destination = .dummy
}

public extension EnvironmentValues {
    /// The destination this view renders, injected by Scaffolding.
    ///
    /// ```swift
    /// @Environment(\.destination) private var destination
    /// ```
    ///
    /// Call ``Destination/dismiss()`` or ``Destination/dismiss(returning:)`` to
    /// close the screen. Read ``Destination/presentationType``,
    /// ``Destination/meta``, or ``Destination/column`` to adapt it. Outside a
    /// coordinator, such as a view previewed alone, this is a placeholder that
    /// reads `.root` and whose `dismiss()` does nothing. See
    /// <doc:Essentials#Use-the-destination-value>.
    @MainActor
    var destination: Destination {
        get { self[DestinationEnvironmentKey.self] }
        set { self[DestinationEnvironmentKey.self] = newValue }
    }
}

/// A route resolved into a screen or child coordinator, with its routing
/// metadata.
///
/// Views read their destination with `@Environment(\.destination)` to close
/// themselves or adapt their chrome:
///
/// ```swift
/// struct CloseButton: View {
///     @Environment(\.destination) private var destination
///
///     var body: some View {
///         if destination.presentationType.isModal {
///             Button("Close") { destination.dismiss() }
///         }
///     }
/// }
/// ```
///
/// The generated `Destinations` enum creates destinations through
/// ``Destinationable/value(for:)``; you don't create them yourself.
///
/// ## Topics
///
/// ### Closing the Screen
///
/// - ``dismiss()``
/// - ``dismiss(returning:)``
///
/// ### Reading Where the Screen Is
///
/// - ``presentationType``
/// - ``routeType``
/// - ``meta``
/// - ``column``
///
/// ### Tab Metadata
///
/// - ``badge``
/// - ``accessibilityIdentifier``
///
/// ### Deprecated Compatibility
///
/// - ``modalConfiguration``
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

        /// A value handed back by a result-bearing dismissal or pop,
        /// consumed by the `awaiting:` navigation APIs.
        var result: Any?

        private var continuations: [UUID: CheckedContinuation<Void, Never>] = [:]

        /// Captures only this destination's lifetime, so callers can configure
        /// the child before waiting without starting an unstructured task.
        func resultWaiter<Result>(for resultType: Result.Type) -> @MainActor () async -> Result? {
            { [self] in
                await awaitResolution()
                return Task.isCancelled ? nil : result as? Result
            }
        }

        func resolve() {
            guard !didResolve else { return }
            didResolve = true
            onDismiss?()
            onDismiss = nil
            let pending = continuations
            continuations = [:]
            for continuation in pending.values {
                continuation.resume()
            }
        }

        /// Cancellation releases this waiter without dismissing shared UI.
        func awaitResolution() async {
            guard !didResolve, !Task.isCancelled else { return }
            let id = UUID()
            await withTaskCancellationHandler {
                await withCheckedContinuation { continuation in
                    guard !didResolve, !Task.isCancelled else {
                        continuation.resume()
                        return
                    }
                    continuations[id] = continuation
                }
            } onCancel: {
                Task { @MainActor in
                    self.continuations.removeValue(forKey: id)?.resume()
                }
            }
        }

    }

    @MainActor
    final class CoordinatableCache {
        private var factory: (() -> (any Coordinatable, AnyView?))?
        private var cached: (any Coordinatable, AnyView?)?

        init(_ factory: @escaping () -> any Coordinatable) {
            self.factory = { (factory(), nil) }
        }

        init<V: View>(_ factory: @escaping () -> (any Coordinatable, V)) {
            self.factory = {
                let (coordinator, label) = factory()
                return (coordinator, AnyView(label))
            }
        }

        init<V: View>(coordinator: any Coordinatable, label: V) {
            cached = (coordinator, AnyView(label))
        }

        private func materialize() -> (any Coordinatable, AnyView?) {
            if let cached { return cached }
            let value = factory!()
            cached = value
            factory = nil
            return value
        }

        var coordinatable: any Coordinatable { materialize().0 }
        var materializedCoordinatable: (any Coordinatable)? { cached?.0 }
        var view: AnyView? { materialize().1 }
    }

    /// This destination instance's identity. Two destinations for the same
    /// case have different IDs.
    public internal(set) var id: UUID = .init()

    private var _resolution = ResolutionState()
    var resolution: ResolutionState { _resolution }

    private var _view: AnyView?
    private var _tabItem: AnyView?
    var _coordinatable: CoordinatableCache?

    var tabRole: TabRole?

    var pushType: PresentationType?

    /// The original `Destinations` enum value this destination was resolved
    /// from, when known. Used for navigation-state capture.
    private var _source: Any?
    var source: Any? { _source }

    /// Deprecated. Keep presentation settings in your view's inputs or state
    /// instead.
    ///
    /// Only ``ModalPresentationType/sheet(detents:dragIndicator:interactiveDismissDisabled:)``
    /// sets this; native modifiers are not reflected.
    @available(*, deprecated, message: "Apply SwiftUI presentation modifiers to the presented view and keep any settings it needs in view inputs or state. Native modifiers are not reflected in this property.")
    public internal(set) var modalConfiguration: SheetConfiguration? {
        get {
            sheetConfiguration.map {
                SheetConfiguration(
                    detents: $0.detents,
                    dragIndicator: $0.dragIndicator,
                    interactiveDismissDisabled: $0.interactiveDismissDisabled
                )
            }
        }
        set {
            sheetConfiguration = newValue.map {
                LegacySheetConfiguration(
                    detents: $0.detents,
                    dragIndicator: $0.dragIndicator,
                    interactiveDismissDisabled: $0.interactiveDismissDisabled
                )
            }
        }
    }

    var sheetConfiguration: LegacySheetConfiguration?

    /// The badge on this destination's tab item, or `nil`.
    ///
    /// Set it with `setBadge(_:for:)` on the tab coordinator.
    public internal(set) var badge: String?

    /// The accessibility identifier on this destination's tab item, or `nil`.
    ///
    /// Set it with ``TabCoordinatable/setTabAccessibilityIdentifier(_:for:)``.
    public internal(set) var accessibilityIdentifier: String?

    /// How this destination entered its own coordinator.
    ///
    /// `.root` for a coordinator's root, a tab, or a split column; otherwise
    /// `.push`, `.sheet`, or `.fullScreenCover`. A flow's root reads `.root`
    /// even when the flow is presented; use ``presentationType`` for chrome.
    public internal(set) var routeType: DestinationType = .root

    /// The split column this destination occupies, or `nil`.
    ///
    /// Only destinations a ``SplitCoordinatable`` owns directly have a column.
    /// Screens inside a child flow hosted in a column read `nil`.
    public internal(set) var column: SplitColumn?

    /// How this screen appears: `.root`, `.push`, `.sheet`, or
    /// `.fullScreenCover`.
    ///
    /// Roots, tabs, and columns inherit their host's presentation: the root of
    /// a flow presented as a sheet reads `.sheet`, and the root of a pushed
    /// child flow reads `.push`. They read `.root` only when nothing above them
    /// was pushed or presented. Use this, not ``routeType``, to choose Back or
    /// Close.
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

    /// The route case this destination was built from, without its associated
    /// values.
    ///
    /// Cast it to the owner's meta type to compare:
    /// `(destination.meta as? HomeCoordinator.Destinations.Meta) == .detail`.
    public let meta: any DestinationMeta
    weak var parent: (any Coordinatable)?

    /// The user-facing dismissal callback, stored on the shared
    /// resolution state so a value-copy of the destination still
    /// reflects updates made to the original.
    var onDismiss: (() -> Void)? {
        guard let cb = _resolution.onDismiss else { return nil }
        return { cb() }
    }

    var coordinatable: (any Coordinatable)? {
        guard parent != nil else { return materializedCoordinatable }
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
        guard parent != nil, let item = _tabItem ?? _coordinatable?.view else { return nil }
        return AnyView(item.environment(\.destination, self))
    }

    // MARK: - Basic Initializers

    /// Creates a destination that shows `value`. Generated code calls this.
    public init<V: View>(
        _ value: V,
        meta: any DestinationMeta,
        parent: any Coordinatable
    ) {
        self._view = AnyView(value)
        self.meta = meta
        self.parent = parent
    }

    /// Creates a destination backed by a child coordinator, created on first
    /// use. Generated code calls this.
    public init(
        _ factory: @escaping () -> any Coordinatable,
        meta: any DestinationMeta,
        parent: any Coordinatable
    ) {
        self._coordinatable = CoordinatableCache(factory)
        self.meta = meta
        self.parent = parent
    }

    /// Creates a tab destination backed by a child coordinator, with a tab
    /// label. Generated code calls this.
    public init<V: View>(
        _ factory: @escaping () -> (any Coordinatable, V),
        meta: any DestinationMeta,
        parent: any Coordinatable
    ) {
        self._coordinatable = CoordinatableCache(factory)
        self.meta = meta
        self.parent = parent
    }

    /// Creates a tab destination with content and a tab label. Generated code
    /// calls this.
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

    /// Creates a tab destination with content and a tab role. Generated code
    /// calls this.
    public init<V: View>(
        _ factory: @escaping () -> (V, TabRole),
        meta: any DestinationMeta,
        parent: any Coordinatable
    ) {
        let (v, role) = factory()

        self._view = AnyView(v)
        self.meta = meta
        self.parent = parent
        self.tabRole = role
    }

    /// Creates a tab destination backed by a child coordinator, with a tab
    /// role. Generated code calls this.
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
        self.tabRole = role
    }

    /// Creates a tab destination with content, a tab label, and a tab role.
    /// Generated code calls this.
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
        self.tabRole = role
    }

    /// Creates a tab destination backed by a child coordinator, with a tab
    /// label and a tab role. Generated code calls this.
    public init<V: View>(
        _ factory: @escaping () -> (any Coordinatable, V, TabRole),
        meta: any DestinationMeta,
        parent: any Coordinatable
    ) {
        let result = factory()

        self._coordinatable = CoordinatableCache(coordinator: result.0, label: result.1)
        self.meta = meta
        self.parent = parent
        self.tabRole = result.2
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

    /// Structural content survives removal of its coordinator. Give a reused
    /// coordinator a fresh dismissal lifetime; retained old copies stay inert.
    mutating func renewDismissalIfResolved() {
        if _resolution.didResolve {
            _resolution = ResolutionState()
        }
    }

    mutating func setRouteType(_ value: DestinationType) {
        routeType = value
    }

    mutating func setColumn(_ value: SplitColumn) {
        column = value
    }

    mutating func setSource(_ value: Any) {
        _source = value
    }

    mutating func setModalConfiguration(_ value: LegacySheetConfiguration?) {
        sheetConfiguration = value
    }

    // MARK: - Resolution

    /// Fires the destination's `onDismiss` callback exactly once.
    /// Called from every removal site: pop, popToRoot, popToFirst/Last,
    /// setRoot, dismissCoordinator, removeModalDestination, sheet swipe.
    func resolveDismissal() {
        resolveDismissals([self])
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
