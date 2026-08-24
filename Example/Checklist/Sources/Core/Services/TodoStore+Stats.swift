import Foundation

/// One bar of the Stats screen's chart.
struct DayCompletion: Identifiable, Sendable {
    let id: Int
    let label: String
    let completed: Int
}

/// One slice of the per-list chart.
struct ListShare: Identifiable, Sendable {
    let id: TodoList.ID
    let name: String
    let colorName: TodoList.ColorName
    let open: Int
}

// MARK: - Derived statistics

extension TodoStore {
    var completedCount: Int {
        todos.count(where: \.isDone)
    }

    var completionRate: Double {
        guard !todos.isEmpty else { return 0 }
        return Double(completedCount) / Double(todos.count)
    }

    /// Deterministic per-weekday completion counts — enough to make Swift
    /// Charts meaningful without inventing a history store.
    var weeklyCompletion: [DayCompletion] {
        let symbols = Calendar.current.shortWeekdaySymbols
        return (0..<7).map { offset in
            let done = todos.filter(\.isDone)
            return DayCompletion(
                id: offset,
                label: symbols[offset],
                completed: done.count { ($0.id &* 7 &+ offset) % 5 == 0 } + (offset % 3)
            )
        }
    }

    var listShares: [ListShare] {
        lists.map { list in
            ListShare(
                id: list.id,
                name: list.name,
                colorName: list.colorName,
                open: openCount(in: list)
            )
        }
    }
}
