//
//  Navigator.swift
//  Scaffolding
//
//  Created by Alexandr Valíček on 05.07.2026.
//

import SwiftUI

/// Type-independent navigation actions for the nearest coordinator.
///
/// Scaffolding injects a `Navigator` into the environment of every view it
/// manages, alongside the typed coordinator injection. Reusable views —
/// design-system components, shared screens living in modules that cannot
/// know the concrete coordinator type — can perform the type-independent
/// operations without importing the coordinator:
///
/// ```swift
/// struct CloseButton: View {
///     @Environment(\.navigator) private var navigator
///
///     var body: some View {
///         Button("Close") { navigator.dismissModal() }
///     }
/// }
/// ```
///
/// Routing to *destinations* still requires the typed coordinator from
/// `@Environment(MyCoordinator.self)` — by design, `Navigator` only
/// exposes operations that need no destination knowledge.
///
/// The coordinator is held weakly; actions on a `Navigator` that outlives
/// its coordinator are safe no-ops. The default value (outside any
/// coordinator hierarchy, e.g. previews) has no coordinator, so every
/// action is a no-op there as well.
@MainActor
public struct Navigator {
    /// The coordinator the actions operate on, if it is still alive.
    public private(set) weak var coordinator: (any Coordinatable)?

    /// Creates a navigator with no coordinator; all actions are no-ops.
    public init() { }

    /// Creates a navigator operating on the given coordinator.
    public init(_ coordinator: any Coordinatable) {
        self.coordinator = coordinator
    }

    /// Pops the top destination of the nearest flow coordinator.
    /// No-op when the nearest coordinator is not a flow.
    public func pop() {
        (coordinator as? any FlowCoordinatable)?.pop()
    }

    /// Pops the nearest flow coordinator to its root.
    /// No-op when the nearest coordinator is not a flow.
    public func popToRoot() {
        (coordinator as? any FlowCoordinatable)?.popToRoot()
    }

    /// Dismisses the most recently presented modal on the nearest
    /// coordinator. See ``Coordinatable/dismissModal()``.
    public func dismissModal() {
        coordinator?.dismissModal()
    }

    /// Dismisses every modal presented on the nearest coordinator.
    /// See ``Coordinatable/dismissAllModals()``.
    public func dismissAllModals() {
        coordinator?.dismissAllModals()
    }

    /// Dismisses the nearest coordinator from its parent.
    /// See ``Coordinatable/dismissCoordinator()``.
    public func dismissCoordinator() {
        coordinator?.dismissCoordinator()
    }

    /// Dismisses the nearest coordinator, handing a result back to its
    /// presenter. See ``Coordinatable/dismissCoordinator(returning:)``.
    public func dismissCoordinator<Result>(returning result: Result) {
        coordinator?.dismissCoordinator(returning: result)
    }
}

private struct NavigatorEnvironmentKey: @MainActor EnvironmentKey {
    @MainActor static let defaultValue = Navigator()
}

public extension EnvironmentValues {
    /// Navigation actions for the nearest coordinator in the hierarchy.
    ///
    /// Scaffolding injects this value automatically for every view it
    /// manages. Outside a coordinator hierarchy the actions are no-ops.
    @MainActor
    var navigator: Navigator {
        get { self[NavigatorEnvironmentKey.self] }
        set { self[NavigatorEnvironmentKey.self] = newValue }
    }
}
