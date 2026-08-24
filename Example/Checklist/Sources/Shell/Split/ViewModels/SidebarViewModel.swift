import SwiftUI
import Observation

/// Sidebar data + domain intents. No navigation: the view calls the
/// coordinator for that.
@MainActor
@Observable
final class SidebarViewModel {
    let store: TodoStore

    /// Bound to a native alert's text field.
    var newListName = ""
    var isAddingList = false
    var pendingDeletion: TodoList?

    init(store: TodoStore) {
        self.store = store
    }

    var smartLists: [SmartList] { SmartList.allCases }
    var lists: [TodoList] { store.lists }

    func count(for smartList: SmartList) -> Int {
        store.count(in: smartList)
    }

    func count(for list: TodoList) -> Int {
        store.openCount(in: list)
    }

    func confirmAddList() {
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

    func delete(_ list: TodoList) {
        store.delete(list: list)
    }
}
