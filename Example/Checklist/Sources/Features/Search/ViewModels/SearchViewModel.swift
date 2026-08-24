import SwiftUI
import Observation

/// Search state and results. The query lives here rather than in `@State`
/// because it is what the screen *is* about, not incidental UI chrome.
@MainActor
@Observable
final class SearchViewModel {
    /// Backs a native `.searchScopes` picker.
    enum Scope: String, CaseIterable, Identifiable {
        case all, open, done, flagged

        var id: String { rawValue }
        var name: String {
            switch self {
            case .all: "All"
            case .open: "Open"
            case .done: "Done"
            case .flagged: "Flagged"
            }
        }
    }

    let store: TodoStore
    var query = ""
    var scope: Scope = .all

    init(store: TodoStore) {
        self.store = store
    }

    var results: [Todo] {
        store.todos.filter { todo in
            matchesScope(todo) && matchesQuery(todo)
        }
    }

    var hasQuery: Bool { !query.trimmingCharacters(in: .whitespaces).isEmpty }

    func listName(for todo: Todo) -> String? {
        store.list(id: todo.listID)?.name
    }

    func toggleDone(_ todo: Todo) { store.toggleDone(todo) }
    func toggleFlag(_ todo: Todo) { store.toggleFlag(todo) }
    func delete(_ todo: Todo) { store.delete(todo) }

    private func matchesScope(_ todo: Todo) -> Bool {
        switch scope {
        case .all: true
        case .open: !todo.isDone
        case .done: todo.isDone
        case .flagged: todo.isFlagged
        }
    }

    private func matchesQuery(_ todo: Todo) -> Bool {
        guard hasQuery else { return true }
        let needle = query.trimmingCharacters(in: .whitespaces)
        return todo.title.localizedCaseInsensitiveContains(needle)
            || todo.notes.localizedCaseInsensitiveContains(needle)
            || todo.tags.contains { $0.localizedCaseInsensitiveContains(needle) }
    }
}
