import SwiftUI
import Scaffolding

/// The signed-in shell: four independent tabs, each its own flow.
///
/// The Stinsen demo wraps three of these tabs in `NavigationViewCoordinator`
/// to give them a navigation container. Here each tab route just returns
/// its `FlowCoordinatable`, which supplies its own `NavigationStack`.
@MainActor
@Observable
@Scaffoldable
final class AuthenticatedCoordinator: @MainActor TabCoordinatable {
    var tabItems = TabItems<AuthenticatedCoordinator>(
        tabs: [.home, .todos, .profile, .testbed]
    )

    let user: User
    let store: TodosStore
    let toasts: ToastCenter

    init(user: User, toasts: ToastCenter) {
        self.user = user
        self.store = TodosStore(user: user)
        self.toasts = toasts
    }

    // MARK: Routes
    // (any Coordinatable, some View) ⇒ a coordinator tab plus its label.

    func home() -> (any Coordinatable, some View) { makeHome() }

    func todos() -> (any Coordinatable, some View) { makeTodos() }

    func profile() -> (any Coordinatable, some View) { makeProfile() }

    func testbed() -> (any Coordinatable, some View) { makeTestbed() }

    /// Intercepts **UI-driven** tab changes. Returns `Bool`, so the macro
    /// never tracks it — no `@ScaffoldingIgnored` needed.
    ///
    /// Re-tapping the selected tab pops that flow to its root, which is
    /// what the Stinsen demo wires up with `onTapped`.
    func shouldSelect(tab: Destinations.Meta, isReselection: Bool) -> Bool {
        guard isReselection else { return true }
        popTabToRoot(tab)
        return true
    }
}
