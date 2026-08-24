import SwiftUI
import Observation

/// Editing surface for one task. Every property writes straight through to
/// the store, so `Form` controls can bind to it directly and any other
/// screen showing the task updates with it.
@MainActor
@Observable
final class TodoDetailViewModel {
    private let id: Todo.ID
    let store: TodoStore

    init(todo: Todo, store: TodoStore) {
        self.id = todo.id
        self.store = store
    }

    /// The live task — re-read from the store so external edits show up.
    /// Falls back to a placeholder if it was deleted while open.
    var todo: Todo {
        store.todo(id: id) ?? Todo(id: id, title: "Deleted task", listID: "")
    }

    var exists: Bool { store.todo(id: id) != nil }

    var title: String {
        get { todo.title }
        set { write { $0.title = newValue } }
    }

    var notes: String {
        get { todo.notes }
        set { write { $0.notes = newValue } }
    }

    var priority: Priority {
        get { todo.priority }
        set { write { $0.priority = newValue } }
    }

    var isDone: Bool {
        get { todo.isDone }
        set { write { $0.isDone = newValue } }
    }

    var isFlagged: Bool {
        get { todo.isFlagged }
        set { write { $0.isFlagged = newValue } }
    }

    var hasDueDate: Bool {
        get { todo.dueDate != nil }
        set { write { $0.dueDate = newValue ? ($0.dueDate ?? .now) : nil } }
    }

    var dueDate: Date {
        get { todo.dueDate ?? .now }
        set { write { $0.dueDate = newValue } }
    }

    var listName: String { store.list(id: todo.listID)?.name ?? "—" }
    var listColor: Color { store.list(id: todo.listID)?.color ?? .gray }

    func delete() { store.delete(todo) }

    private func write(_ change: (inout Todo) -> Void) {
        var copy = todo
        change(&copy)
        store.update(copy)
    }
}
