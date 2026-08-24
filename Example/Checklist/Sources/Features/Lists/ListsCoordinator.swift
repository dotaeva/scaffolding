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
    // The route table: one line per destination, with the bodies in
    // ListsCoordinator+Factory.swift. These declarations have to stay in the class
    // body — @Scaffoldable scans only the class declaration, so a route
    // moved to an extension is silently untracked.

    func lists() -> some View { makeLists() }

    func tasks(source: TaskSource) -> some View { makeTasks(source: source) }

    func todo(todo: Todo) -> any Coordinatable { makeTodo(todo: todo) }

    func newTodo(source: TaskSource) -> any Coordinatable { makeNewTodo(source: source) }
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
