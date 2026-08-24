import SwiftUI
import Observation

/// The lists overview: smart filters, user lists, and their progress.
@MainActor
@Observable
final class ListsViewModel {
    let store: TodoStore

    var newListName = ""
    var isAddingList = false

    init(store: TodoStore) {
        self.store = store
    }

    var smartLists: [SmartList] { SmartList.allCases }
    var lists: [TodoList] { store.lists }

    func count(for smartList: SmartList) -> Int { store.count(in: smartList) }
    func openCount(for list: TodoList) -> Int { store.openCount(in: list) }

    /// Share of a list's tasks that are done — drives a native
    /// `ProgressView` per row.
    func progress(for list: TodoList) -> Double {
        let all = store.todos.filter { $0.listID == list.id }
        guard !all.isEmpty else { return 0 }
        return Double(all.count(where: \.isDone)) / Double(all.count)
    }

    func addList() {
        let name = newListName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        store.add(list: TodoList(
            id: name.lowercased().replacingOccurrences(of: " ", with: "-"),
            name: name,
            symbol: "list.bullet",
            colorName: TodoList.ColorName.allCases.randomElement() ?? .blue
        ))
        newListName = ""
    }

    func delete(at offsets: IndexSet) {
        for index in offsets {
            store.delete(list: lists[index])
        }
    }
}
