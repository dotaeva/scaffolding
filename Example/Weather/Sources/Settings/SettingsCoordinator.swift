import SwiftUI
import Scaffolding

/// Settings: a tab on iPhone, a sheet on iPad/macOS — the same flow, and
/// it never knows which. Exercises awaiting pickers, presenter-closed
/// overlays, dismissAllModals, and reaching an ancestor coordinator.
@MainActor
@Observable
@Scaffoldable(codable: true)
final class SettingsCoordinator: @MainActor FlowCoordinatable {
    var stack = FlowStack<SettingsCoordinator>(root: .settings)

    let store: WeatherStore

    init(store: WeatherStore) {
        self.store = store
    }

    // MARK: Routes

    func settings() -> some View { SettingsScreen() }
    func about() -> some View { AboutScreen() }
    // The debug sheet doubles as a pushed screen here — its chrome adapts
    // via \.destination.
    func tree() -> some View { HierarchyDumpSheet() }
    // View-only modal with no controls — only the presenter can close it.
    func refreshing() -> some View { RefreshOverlay() }
    // Child coordinator whose whole job is returning a value; it opts out
    // of environment injection (see UnitsPickerCoordinator).
    func unitsPicker() -> any Coordinatable {
        UnitsPickerCoordinator(current: store.units)
    }
}

// MARK: - Actions

extension SettingsCoordinator {
    func showAbout() {
        route(to: .about, policy: .distinct)
    }

    func showTree() {
        route(to: .tree, policy: .distinct)
    }

    /// present(awaiting:) against a coordinator that resolves the value
    /// with dismissCoordinator(returning:).
    func changeUnits() {
        Task {
            guard let picked = await present(
                .unitsPicker,
                as: .sheet(detents: [.medium]),
                awaiting: Units.self
            ) else { return }
            store.units = picked
        }
    }

    /// A modal the user can't interact with, closed by the presenter when
    /// the work finishes — dismissModal() is the only way out of a
    /// view-only modal programmatically.
    func refreshAll() {
        guard !isPresentingModal else { return }
        present(.refreshing, as: .sheet(detents: [.medium], interactiveDismissDisabled: true))
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            dismissModal()
        }
    }

    /// Emergency hatch: closes every modal this coordinator presented.
    func closeAllModals() {
        dismissAllModals()
    }

    /// An action that belongs to the app root — ancestor(ofType:) walks
    /// the parent chain instead of storing references across the tree.
    func resetOnboarding() {
        ancestor(ofType: AppCoordinator.self)?.resetOnboarding()
    }
}
