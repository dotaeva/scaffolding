import SwiftUI
import Observation

/// The single source of truth for *domain* state.
///
/// The architecture in one line: the **store** owns data, **ViewModels**
/// own per-screen derivations and intents, **coordinators** own navigation,
/// and **views** own layout. Nothing owns two of those.
@MainActor
@Observable
final class TodoStore {
    // Writes live in TodoStore+Mutations (a same-module extension), so
    // these can't be `private(set)` — the convention is that views and
    // ViewModels only ever read them.
    var lists: [TodoList]
    var todos: [Todo]
    var tags: [String]

    /// Set during onboarding, changeable in Settings.
    var showsCompleted = false
    var sortByDueDate = true

    init(
        lists: [TodoList] = SampleData.lists,
        todos: [Todo] = SampleData.todos,
        tags: [String] = SampleData.tags
    ) {
        self.lists = lists
        self.todos = todos
        self.tags = tags
    }

    // MARK: Queries

    func list(id: TodoList.ID) -> TodoList? {
        lists.first { $0.id == id }
    }

    func todo(id: Todo.ID) -> Todo? {
        todos.first { $0.id == id }
    }

    func todos(in list: TodoList) -> [Todo] {
        sorted(todos.filter { $0.listID == list.id && (showsCompleted || !$0.isDone) })
    }

    func todos(in smartList: SmartList) -> [Todo] {
        sorted(todos.filter(smartList.matches))
    }

    func openCount(in list: TodoList) -> Int {
        todos.count { $0.listID == list.id && !$0.isDone }
    }

    func count(in smartList: SmartList) -> Int {
        todos.count(where: smartList.matches)
    }

    var overdueCount: Int {
        todos.count(where: \.isOverdue)
    }

    private func sorted(_ input: [Todo]) -> [Todo] {
        guard sortByDueDate else { return input.sorted { $0.priority > $1.priority } }
        return input.sorted { lhs, rhs in
            switch (lhs.dueDate, rhs.dueDate) {
            case let (l?, r?): l < r
            case (nil, _?): false
            case (_?, nil): true
            case (nil, nil): lhs.priority > rhs.priority
            }
        }
    }
}
