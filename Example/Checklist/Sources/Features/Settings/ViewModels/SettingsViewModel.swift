import SwiftUI
import Observation

/// Preferences and tag management.
@MainActor
@Observable
final class SettingsViewModel {
    let store: TodoStore

    var newTag = ""

    init(store: TodoStore) {
        self.store = store
    }

    var sortByDueDate: Bool {
        get { store.sortByDueDate }
        set { store.sortByDueDate = newValue }
    }

    var showsCompleted: Bool {
        get { store.showsCompleted }
        set { store.showsCompleted = newValue }
    }

    var tags: [String] { store.tags }
    var taskCount: Int { store.todos.count }
    var listCount: Int { store.lists.count }
    var completedCount: Int { store.completedCount }

    func addTag() {
        store.add(tag: newTag)
        newTag = ""
    }

    func deleteTags(at offsets: IndexSet) {
        for index in offsets {
            store.delete(tag: tags[index])
        }
    }

    func usageCount(of tag: String) -> Int {
        store.todos.count { $0.tags.contains(tag) }
    }
}
