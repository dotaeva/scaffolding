import SwiftUI
import Scaffolding

/// iPad / macOS shell: a three-column `NavigationSplitView` — lists in the
/// sidebar, that list's tasks in the middle, the selected task's flow in
/// the detail column.
///
/// A `SplitCoordinatable` must never live inside a `FlowCoordinatable`
/// (SwiftUI does not support `NavigationSplitView` inside a
/// `NavigationStack`). Here it is a root child, one of the legal hosts.
@MainActor
@Observable
@Scaffoldable(codable: true)
final class MainSplitCoordinator: @MainActor SplitCoordinatable {
    var columns = SplitColumns<MainSplitCoordinator>(
        sidebar: .sidebar,
        content: .tasks(source: .smart(.today)),
        detail: .noSelection,
        visibility: .doubleColumn,
        preferredCompactColumn: .content
    )

    let store: TodoStore

    /// Domain state, not navigation state: what the sidebar highlights and
    /// which task is open. `setContent`/`setDetail` *replace* a column, so
    /// re-selection has to be guarded on this rather than on
    /// `RoutePolicy.distinct`, which only compares destination *cases*.
    var selectedSource: TaskSource = .smart(.today)
    var selectedTodoID: Todo.ID?

    init(store: TodoStore) {
        self.store = store
    }

    // MARK: Routes
    // The route table: one line per destination, with the bodies in
    // MainSplitCoordinator+Factory.swift. These declarations have to stay in the class
    // body — @Scaffoldable scans only the class declaration, so a route
    // moved to an extension is silently untracked.
    // Column assignment lives in the SplitColumns initializer and in the
    // setContent/setDetail calls — routes keep plain auto-tracked returns.

    func sidebar() -> some View { makeSidebar() }

    func tasks(source: TaskSource) -> some View { makeTasks(source: source) }

    func noSelection() -> some View { makeNoSelection() }

    func detail(todo: Todo) -> any Coordinatable { makeDetail(todo: todo) }

    func playground() -> any Coordinatable { makePlayground() }

    func newTodo(source: TaskSource) -> any Coordinatable { makeNewTodo(source: source) }

    func settings() -> any Coordinatable { makeSettings() }
}
