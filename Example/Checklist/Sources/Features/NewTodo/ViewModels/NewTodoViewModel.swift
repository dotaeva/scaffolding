import SwiftUI
import Observation

/// The draft a new task is assembled from. Owned by
/// ``NewTodoCoordinator`` and shared by its two screens.
@MainActor
@Observable
final class NewTodoViewModel {
    private let store: TodoStore

    var title = ""
    var listID: TodoList.ID
    var priority: Priority = .none
    var hasDueDate = false
    var dueDate: Date = .now.addingTimeInterval(3_600)
    var tags: Set<String> = []

    /// Set after the pushed picker pops, so the compose screen can show
    /// what came back from the awaited push.
    private(set) var lastPickedListName: String?

    init(source: TaskSource, store: TodoStore) {
        self.store = store
        listID = source.destinationListID(fallback: store.lists.first?.id ?? "")
    }

    var lists: [TodoList] { store.lists }
    var allTags: [String] { store.tags }
    var canSave: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty }

    var listName: String { store.list(id: listID)?.name ?? "—" }
    var listColor: Color { store.list(id: listID)?.color ?? .gray }

    func select(list: TodoList) {
        listID = list.id
    }

    func toggle(tag: String) {
        if tags.contains(tag) { tags.remove(tag) } else { tags.insert(tag) }
    }

    func didReturnFromPicker() {
        lastPickedListName = listName
    }

    /// Builds the task the presenter will receive. The store assigns the
    /// id but does not insert it — the presenter does that when the
    /// `awaiting:` call resumes.
    func build() -> Todo? {
        guard canSave else { return nil }
        return store.makeTodo(
            title: title.trimmingCharacters(in: .whitespaces),
            listID: listID,
            dueDate: hasDueDate ? dueDate : nil,
            priority: priority,
            tags: allTags.filter(tags.contains)
        )
    }
}
