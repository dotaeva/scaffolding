import SwiftUI
import Scaffolding

/// The iPhone Lists tab: lists overview → that list's tasks → one task.
/// Three levels on one stack, the middle one sharing its screen with the
/// iPad's content column.
@MainActor
@Observable
@Scaffoldable(codable: true)
final class ListsCoordinator: @MainActor FlowCoordinatable {
    var stack = FlowStack<ListsCoordinator>(root: .lists)

    let store: TodoStore

    init(store: TodoStore) {
        self.store = store
    }

    // MARK: Routes

    func lists() -> some View {
        ListsView(viewModel: ListsViewModel(store: store))
    }

    /// The shared task screen — here its intents push instead of replacing
    /// a split column.
    func tasks(source: TaskSource) -> some View {
        TaskListView(
            viewModel: TaskListViewModel(source: source, store: store),
            onSelect: { [weak self] todo in self?.open(todo) },
            onAdd: { [weak self] in self?.addTodo(in: source) }
        )
    }

    func todo(todo: Todo) -> any Coordinatable {
        TodoDetailCoordinator(todo: todo, store: store)
    }

    func newTodo(source: TaskSource) -> any Coordinatable {
        NewTodoCoordinator(source: source, store: store)
    }
}

// MARK: - Navigation

extension ListsCoordinator {
    func showTasks(in source: TaskSource) {
        route(to: .tasks(source: source), policy: .distinct)
    }

    func open(_ todo: Todo) {
        route(to: .todo(todo: todo), policy: .distinct)
    }

    func addTodo(in source: TaskSource) {
        Task {
            let created = await present(
                .newTodo(source: source),
                as: .sheet(detents: [.large]),
                awaiting: Todo.self
            )
            guard let created else { return }
            store.add(created)
            open(created)
        }
    }

    /// Deep-link leg: land on a task with its list screen underneath, so
    /// "back" behaves as if the user had walked there.
    func showTodo(_ todo: Todo) {
        popToRoot()
        if let list = store.list(id: todo.listID) {
            showTasks(in: .list(list))
        }
        open(todo)
    }
}
