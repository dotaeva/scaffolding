import Foundation

// MARK: - Mutations
// Every write goes through here, so ViewModels stay thin and tests can
// drive the domain without touching a view.

extension TodoStore {
    func add(_ todo: Todo) {
        todos.append(todo)
    }

    /// Builds a task with the next free id — used by the new-task sub-flow.
    func makeTodo(
        title: String,
        listID: TodoList.ID,
        dueDate: Date?,
        priority: Priority,
        tags: [String]
    ) -> Todo {
        Todo(
            id: (todos.map(\.id).max() ?? 0) + 1,
            title: title,
            isDone: false,
            dueDate: dueDate,
            priority: priority,
            listID: listID,
            tags: tags
        )
    }

    func update(_ todo: Todo) {
        guard let index = todos.firstIndex(where: { $0.id == todo.id }) else { return }
        todos[index] = todo
    }

    func toggleDone(_ todo: Todo) {
        guard let index = todos.firstIndex(where: { $0.id == todo.id }) else { return }
        todos[index].isDone.toggle()
    }

    func toggleFlag(_ todo: Todo) {
        guard let index = todos.firstIndex(where: { $0.id == todo.id }) else { return }
        todos[index].isFlagged.toggle()
    }

    func delete(_ todo: Todo) {
        todos.removeAll { $0.id == todo.id }
    }

    func delete(ids: Set<Todo.ID>) {
        todos.removeAll { ids.contains($0.id) }
    }

    func add(list: TodoList) {
        guard !lists.contains(where: { $0.id == list.id }) else { return }
        lists.append(list)
    }

    func delete(list: TodoList) {
        lists.removeAll { $0.id == list.id }
        todos.removeAll { $0.listID == list.id }
    }

    func rename(list: TodoList, to name: String) {
        guard let index = lists.firstIndex(where: { $0.id == list.id }) else { return }
        lists[index].name = name
    }

    func add(tag: String) {
        let clean = tag.trimmingCharacters(in: .whitespaces).lowercased()
        guard !clean.isEmpty, !tags.contains(clean) else { return }
        tags.append(clean)
    }

    func delete(tag: String) {
        tags.removeAll { $0 == tag }
        for index in todos.indices {
            todos[index].tags.removeAll { $0 == tag }
        }
    }
}
