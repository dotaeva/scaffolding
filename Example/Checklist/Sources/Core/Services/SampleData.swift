import Foundation

/// Seed content. Fixed relative dates keep the demo deterministic — no
/// network, no permissions, and restored navigation always lands on data
/// that still exists.
enum SampleData {
    static let lists: [TodoList] = [
        TodoList(id: "work", name: "Work", symbol: "briefcase.fill", colorName: .blue),
        TodoList(id: "home", name: "Home", symbol: "house.fill", colorName: .green),
        TodoList(id: "reading", name: "Reading", symbol: "book.fill", colorName: .purple),
    ]

    static let tags = ["urgent", "waiting", "quick", "errand"]

    static var todos: [Todo] {
        let day: TimeInterval = 86_400
        return [
            Todo(id: 1, title: "Review pull requests", notes: "Two are waiting on me since Friday.",
                 isFlagged: true, dueDate: .now.addingTimeInterval(-day), priority: .high,
                 listID: "work", tags: ["urgent"]),
            Todo(id: 2, title: "Write release notes", dueDate: .now.addingTimeInterval(3_600),
                 priority: .medium, listID: "work", tags: ["quick"]),
            Todo(id: 3, title: "Plan sprint retro", notes: "Book the small room.",
                 dueDate: .now.addingTimeInterval(2 * day), listID: "work"),
            Todo(id: 4, title: "Ship the beta build", isDone: true,
                 dueDate: .now.addingTimeInterval(-2 * day), priority: .high, listID: "work"),
            Todo(id: 5, title: "Water the plants", dueDate: .now.addingTimeInterval(7_200),
                 listID: "home", tags: ["quick"]),
            Todo(id: 6, title: "Fix the kitchen shelf", notes: "Needs longer screws.",
                 isFlagged: true, priority: .low, listID: "home", tags: ["errand"]),
            Todo(id: 7, title: "Renew the passport", dueDate: .now.addingTimeInterval(9 * day),
                 priority: .medium, listID: "home", tags: ["waiting"]),
            Todo(id: 8, title: "Groceries", isDone: true, listID: "home"),
            Todo(id: 9, title: "Finish The Pragmatic Programmer", listID: "reading"),
            Todo(id: 10, title: "Start Designing Data-Intensive Applications",
                 notes: "Chapter 1–3 this week.", dueDate: .now.addingTimeInterval(4 * day),
                 listID: "reading", tags: ["waiting"]),
            Todo(id: 11, title: "Re-read the SwiftUI navigation docs", isDone: true,
                 listID: "reading", tags: ["quick"]),
        ]
    }
}
