import SwiftUI
import Scaffolding

// MARK: - Factory
// Where each route's screen is actually assembled: views get their
// ViewModels here, child coordinators get their dependencies. The
// route table stays in the class body because @Scaffoldable scans
// only the class declaration — a route in an extension is silently
// untracked — while these `make…` helpers are invisible to it, so
// they need no @ScaffoldingIgnored.

extension SettingsCoordinator {
    func makeSettings() -> some View {
        SettingsView(viewModel: SettingsViewModel(store: store))
    }

    func makeTags() -> some View {
        TagsView(viewModel: SettingsViewModel(store: store))
    }

    func makeAbout() -> some View { AboutView() }

    /// The debug sheet, here as a *pushed* screen — its chrome adapts,
    /// because it reads `\.destination` rather than assuming.
    func makeTree() -> some View { HierarchySheet() }

    /// A view-only modal with no controls: only the presenter can close it.
    func makeSyncing() -> some View { SyncingOverlay() }
}
