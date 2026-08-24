import SwiftUI
import Scaffolding

// MARK: - Factory
// Where each route's screen is actually assembled: views get their
// ViewModels here, child coordinators get their dependencies. The
// route table stays in the class body because @Scaffoldable scans
// only the class declaration — a route in an extension is silently
// untracked — while these `make…` helpers are invisible to it, so
// they need no @ScaffoldingIgnored.

extension ListsCoordinator {
    func makeLists() -> some View {
        ListsView(viewModel: ListsViewModel(store: store))
    }

    /// The shared task screen — here its intents push instead of replacing
    /// a split column.
    func makeTasks(source: TaskSource) -> some View {
        TaskListView(
            viewModel: TaskListViewModel(source: source, store: store),
            onSelect: { [weak self] todo in self?.open(todo) },
            onAdd: { [weak self] in self?.addTodo(in: source) }
        )
    }

    func makeTodo(todo: Todo) -> any Coordinatable {
        TodoDetailCoordinator(todo: todo, store: store)
    }

    func makeNewTodo(source: TaskSource) -> any Coordinatable {
        NewTodoCoordinator(source: source, store: store)
    }
}
