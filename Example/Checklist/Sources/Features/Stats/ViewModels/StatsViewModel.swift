import SwiftUI
import Observation

/// Numbers for the charts. All derived — the store keeps no analytics.
@MainActor
@Observable
final class StatsViewModel {
    let store: TodoStore

    init(store: TodoStore) {
        self.store = store
    }

    var completedCount: Int { store.completedCount }
    var openCount: Int { store.todos.count - store.completedCount }
    var completionRate: Double { store.completionRate }
    var weekly: [DayCompletion] { store.weeklyCompletion }
    var shares: [ListShare] { store.listShares }
    var lists: [TodoList] { store.lists }

    var busiestList: TodoList? {
        store.lists.max { store.openCount(in: $0) < store.openCount(in: $1) }
    }

    func openCount(in list: TodoList) -> Int { store.openCount(in: list) }

    func flaggedCount(in list: TodoList) -> Int {
        store.todos.count { $0.listID == list.id && $0.isFlagged }
    }

    func overdueCount(in list: TodoList) -> Int {
        store.todos.count { $0.listID == list.id && $0.isOverdue }
    }
}
