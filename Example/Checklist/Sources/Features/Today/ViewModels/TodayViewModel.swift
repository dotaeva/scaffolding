import SwiftUI
import Observation

/// Today's agenda, split into overdue and later. Data + domain intents.
@MainActor
@Observable
final class TodayViewModel {
    let store: TodoStore

    init(store: TodoStore) {
        self.store = store
    }

    var overdue: [Todo] {
        store.todos(in: .today).filter(\.isOverdue)
    }

    var later: [Todo] {
        store.todos(in: .today).filter { !$0.isOverdue }
    }

    var isEmpty: Bool { overdue.isEmpty && later.isEmpty }

    var greeting: String {
        switch Calendar.current.component(.hour, from: .now) {
        case 5..<12: "Good morning"
        case 12..<18: "Good afternoon"
        default: "Good evening"
        }
    }

    var progress: Double { store.completionRate }

    func listName(for todo: Todo) -> String? {
        store.list(id: todo.listID)?.name
    }

    func toggleDone(_ todo: Todo) { store.toggleDone(todo) }
    func toggleFlag(_ todo: Todo) { store.toggleFlag(todo) }
    func delete(_ todo: Todo) { store.delete(todo) }
}
