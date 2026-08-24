import SwiftUI

/// The built-in filters at the top of the sidebar — the Reminders-style
/// "Today / Flagged / All" rows. A separate type from ``TodoList`` because
/// these are queries, not containers.
enum SmartList: String, Codable, CaseIterable, Identifiable, Hashable, Sendable {
    case today, flagged, all, completed

    var id: String { rawValue }

    var name: String {
        switch self {
        case .today: "Today"
        case .flagged: "Flagged"
        case .all: "All"
        case .completed: "Completed"
        }
    }

    var symbol: String {
        switch self {
        case .today: "calendar"
        case .flagged: "flag.fill"
        case .all: "tray.full.fill"
        case .completed: "checkmark.circle.fill"
        }
    }

    var tint: Color {
        switch self {
        case .today: .blue
        case .flagged: .orange
        case .all: .gray
        case .completed: .green
        }
    }

    func matches(_ todo: Todo) -> Bool {
        switch self {
        case .today: !todo.isDone && todo.isToday
        case .flagged: !todo.isDone && todo.isFlagged
        case .all: !todo.isDone
        case .completed: todo.isDone
        }
    }
}
