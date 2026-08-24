import SwiftUI
import Observation

/// Drives every task-list screen: the split view's middle column and the
/// pushed list screen in the Lists tab. Data and domain intents only.
@MainActor
@Observable
final class TaskListViewModel {
    let source: TaskSource
    let store: TodoStore

    private(set) var isSyncing = false

    init(source: TaskSource, store: TodoStore) {
        self.source = source
        self.store = store
    }

    var title: String { source.title }

    var todos: [Todo] {
        switch source {
        case .list(let list): store.todos(in: list)
        case .smart(let smart): store.todos(in: smart)
        }
    }

    var isEmpty: Bool { todos.isEmpty }

    func listName(for todo: Todo) -> String? {
        // Inside one list the name would just repeat; smart lists show it.
        guard case .smart = source else { return nil }
        return store.list(id: todo.listID)?.name
    }

    func toggleDone(_ todo: Todo) { store.toggleDone(todo) }
    func toggleFlag(_ todo: Todo) { store.toggleFlag(todo) }
    func delete(_ todo: Todo) { store.delete(todo) }

    func delete(at offsets: IndexSet) {
        let doomed = offsets.map { todos[$0] }
        store.delete(ids: Set(doomed.map(\.id)))
    }

    /// Stands in for a network sync so `.refreshable` has something to do.
    func sync() async {
        isSyncing = true
        try? await Task.sleep(for: .milliseconds(600))
        isSyncing = false
    }
}
