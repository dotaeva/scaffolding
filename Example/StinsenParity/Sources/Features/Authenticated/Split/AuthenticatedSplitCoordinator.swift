import SwiftUI
import Scaffolding

/// The signed-in shell on iPad and Mac: a `NavigationSplitView` where the
/// iPhone's four tabs become sidebar rows.
///
/// The point of the file is how little is in it. `HomeCoordinator`,
/// `ProfileCoordinator`, and `TestbedCoordinator` are the very same flows
/// ``AuthenticatedCoordinator`` hosts as tabs — here they build their
/// `NavigationStack` inside the detail column instead, which is the
/// composition SwiftUI expects, so pushes and modals inside a column are
/// ordinary flow calls and not one line of those flows changes.
///
/// Only Todos differs, because list-then-detail is exactly what a middle
/// column is for: selecting it installs one with `setContent(_:)`, and the
/// other three drop it again with `removeContent()`.
///
/// A `SplitCoordinatable` must never live inside a `FlowCoordinatable`.
/// This one is a ``MainCoordinator`` root child — a legal host.
@MainActor
@Observable
@Scaffoldable
final class AuthenticatedSplitCoordinator: @MainActor SplitCoordinatable {
    /// Two columns at launch: Home needs no task list beside it.
    /// `setContent(_:)` swaps in the three-column form when Todos is
    /// selected, and `removeContent()` swaps back.
    var columns = SplitColumns<AuthenticatedSplitCoordinator>(
        sidebar: .sidebar,
        detail: .home,
        visibility: .all,
        preferredCompactColumn: .sidebar
    )

    let user: User
    let store: TodosStore
    let toasts: ToastCenter

    /// Domain state, not navigation state: what the sidebar highlights and
    /// which task the detail column shows.
    var section: ShellSection = .home
    var selectedTodoID: UUID?

    init(user: User, toasts: ToastCenter) {
        self.user = user
        self.store = TodosStore(user: user)
        self.toasts = toasts
    }

    // MARK: Routes
    // Column assignment lives in the SplitColumns initializer and in the
    // setContent/setDetail calls, so routes keep the plain auto-tracked
    // return types. These declarations have to stay in the class body —
    // @Scaffoldable scans only the class declaration, so a route moved to
    // an extension is silently untracked.

    func sidebar() -> some View { makeSidebar() }

    func todos() -> some View { makeTodos() }

    func todo(id: UUID) -> some View { makeTodo(id: id) }

    func noSelection() -> some View { makeNoSelection() }

    /// The three tab flows, unchanged, in the detail column.

    func home() -> any Coordinatable { makeHome() }

    func profile() -> any Coordinatable { makeProfile() }

    func testbed() -> any Coordinatable { makeTestbed() }

    /// Presented rather than columned, because it returns a value.
    func createTodo() -> any Coordinatable { makeCreateTodo() }
}
