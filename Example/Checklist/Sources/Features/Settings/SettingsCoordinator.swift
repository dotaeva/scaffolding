import SwiftUI
import Scaffolding

/// Settings: a tab on iPhone, a sheet on iPad/Mac — the same flow, and it
/// never knows which. Also the home of the navigation playground, where
/// every push/pop variant can be poked at live.
@MainActor
@Observable
@Scaffoldable(codable: true)
final class SettingsCoordinator: @MainActor FlowCoordinatable {
    var stack = FlowStack<SettingsCoordinator>(root: .settings)

    let store: TodoStore

    init(store: TodoStore) {
        self.store = store
    }

    // MARK: Routes

    func settings() -> some View {
        SettingsView(viewModel: SettingsViewModel(store: store))
    }

    func tags() -> some View {
        TagsView(viewModel: SettingsViewModel(store: store))
    }

    func playground() -> some View { PlaygroundView() }

    func about() -> some View { AboutView() }

    /// The debug sheet, here as a *pushed* screen — its chrome adapts,
    /// because it reads `\.destination` rather than assuming.
    func tree() -> some View { HierarchySheet() }

    /// A view-only modal with no controls: only the presenter can close it.
    func syncing() -> some View { SyncingOverlay() }
}

// MARK: - Chrome

extension SettingsCoordinator {
    /// Declared in an extension, so the macro never sees it. Sizes the flow
    /// when it is presented as a sheet — including whatever it pushes.
    func customize(_ view: AnyView) -> some View {
        view.sheetSizing()
    }
}

// MARK: - Navigation

extension SettingsCoordinator {
    func showTags() { route(to: .tags, policy: .distinct) }
    func showPlayground() { route(to: .playground, policy: .distinct) }

    /// The playground's own push button: `.always`, so the stack actually
    /// grows and the pop family has something to take apart.
    func pushAnotherPlayground() { route(to: .playground) }
    func showAbout() { route(to: .about, policy: .distinct) }
    func showTree() { route(to: .tree, policy: .distinct) }

    /// Presented, then closed by the presenter when the work finishes —
    /// `dismissModal()` is the only way out of a view-only modal.
    func syncNow() {
        guard !isPresentingModal else { return }
        present(.syncing, as: .sheet(detents: [.medium], interactiveDismissDisabled: true))
        Task {
            try? await Task.sleep(for: .seconds(1))
            dismissModal()
        }
    }

    /// Closes every modal this coordinator presented, leaving pushes alone.
    func closeAllModals() {
        dismissAllModals()
    }

    /// An action that belongs to the app root: `ancestor(ofType:)` walks
    /// the parent chain instead of anyone storing cross-tree references.
    func restartOnboarding() {
        ancestor(ofType: AppCoordinator.self)?.restartOnboarding()
    }

    func forgetNavigationState() {
        ancestor(ofType: AppCoordinator.self)?.forgetNavigationState()
    }
}
