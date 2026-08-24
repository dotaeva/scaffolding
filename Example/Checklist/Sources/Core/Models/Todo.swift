import Foundation

/// A single task. Named `Todo` rather than `Task` so it never shadows
/// Swift's concurrency `Task`, which the awaitable navigation APIs use.
///
/// `Codable` + `Hashable` because it travels as a route payload on
/// coordinators that opt into `codable: true` state restoration.
struct Todo: Identifiable, Codable, Hashable, Sendable {
    let id: Int
    var title: String
    var notes: String
    var isDone: Bool
    var isFlagged: Bool
    var dueDate: Date?
    var priority: Priority
    var listID: TodoList.ID
    var tags: [String]

    init(
        id: Int,
        title: String,
        notes: String = "",
        isDone: Bool = false,
        isFlagged: Bool = false,
        dueDate: Date? = nil,
        priority: Priority = .none,
        listID: TodoList.ID,
        tags: [String] = []
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.isDone = isDone
        self.isFlagged = isFlagged
        self.dueDate = dueDate
        self.priority = priority
        self.listID = listID
        self.tags = tags
    }
}

extension Todo {
    var isOverdue: Bool {
        guard !isDone, let dueDate else { return false }
        return dueDate < Date.now
    }

    var isToday: Bool {
        guard let dueDate else { return false }
        return Calendar.current.isDateInToday(dueDate) || isOverdue
    }

    /// "Today, 20:15" / "Yesterday, 19:15" / "Wed, 09:00" / "3 Sept" —
    /// absolute dates only once relative ones stop being useful.
    var dueDescription: String? {
        guard let dueDate else { return nil }
        let calendar = Calendar.current
        let time = dueDate.formatted(date: .omitted, time: .shortened)
        if calendar.isDateInToday(dueDate) { return "Today, \(time)" }
        if calendar.isDateInTomorrow(dueDate) { return "Tomorrow, \(time)" }
        if calendar.isDateInYesterday(dueDate) { return "Yesterday, \(time)" }
        let days = calendar.dateComponents([.day], from: .now, to: dueDate).day ?? 0
        if (0...6).contains(days) {
            return dueDate.formatted(.dateTime.weekday(.abbreviated).hour().minute())
        }
        return dueDate.formatted(.dateTime.day().month(.abbreviated))
    }
}
