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
    // Column assignment lives in the SplitColumns initializer and in the
    // setContent/setDetail calls — routes keep plain auto-tracked returns.

    func sidebar() -> some View {
        SidebarView(viewModel: SidebarViewModel(store: store))
    }

    func tasks(source: TaskSource) -> some View {
        TaskListView(
            viewModel: TaskListViewModel(source: source, store: store),
            selection: Binding(
                get: { [weak self] in self?.selectedTodoID },
                set: { [weak self] id in
                    guard let id, let todo = self?.store.todo(id: id) else { return }
                    self?.select(todo: todo)
                }
            ),
            // The shared screen takes its intents as closures — here they
            // replace a column; in the Lists tab they push instead.
            onSelect: { [weak self] todo in self?.select(todo: todo) },
            onAdd: { [weak self] in self?.addTodo() }
        )
    }

    func noSelection() -> some View {
        ContentUnavailableView(
            "No Task Selected",
            systemImage: "checklist",
            description: Text("Pick a task from the list to see its details.")
        )
    }

    /// A child flow in a column builds its own `NavigationStack` there —
    /// exactly the composition SwiftUI expects — so pushes and modals
    /// inside the detail column are ordinary flow calls. The very same
    /// coordinator is pushed onto a stack on iPhone.
    func detail(todo: Todo) -> any Coordinatable {
        TodoDetailCoordinator(todo: todo, store: store)
    }

    /// Modal sub-flow that hands a new task back to its presenter.
    func newTodo(source: TaskSource) -> any Coordinatable {
        NewTodoCoordinator(source: source, store: store)
    }

    /// The coordinator the iPhone shows as a tab is a sheet here — the
    /// presenter decides, and the flow never knows the difference.
    func settings() -> any Coordinatable { SettingsCoordinator(store: store) }
}
