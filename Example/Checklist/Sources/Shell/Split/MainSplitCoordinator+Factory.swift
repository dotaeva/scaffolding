import SwiftUI
import Scaffolding

// MARK: - Factory
// Where each route's screen is actually assembled: views get their
// ViewModels here, child coordinators get their dependencies. The
// route table stays in the class body because @Scaffoldable scans
// only the class declaration — a route in an extension is silently
// untracked — while these `make…` helpers are invisible to it, so
// they need no @ScaffoldingIgnored.

extension MainSplitCoordinator {
    func makeSidebar() -> some View {
        SidebarView(viewModel: SidebarViewModel(store: store))
    }

    func makeTasks(source: TaskSource) -> some View {
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

    func makeNoSelection() -> some View {
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
    func makeDetail(todo: Todo) -> any Coordinatable {
        TodoDetailCoordinator(todo: todo, store: store)
    }

    /// The playground, shown in the detail column from a sidebar row.
    func makePlayground() -> any Coordinatable { PlaygroundCoordinator() }

    /// Modal sub-flow that hands a new task back to its presenter.
    func makeNewTodo(source: TaskSource) -> any Coordinatable {
        NewTodoCoordinator(source: source, store: store)
    }

    /// The coordinator the iPhone shows as a tab is a sheet here — the
    /// presenter decides, and the flow never knows the difference.
    func makeSettings() -> any Coordinatable { SettingsCoordinator(store: store) }
}
