import Foundation

/// What a task list screen is showing: one of the user's lists, or one of
/// the built-in smart filters.
///
/// It is the payload of the split view's content column and of the pushed
/// list screen, so it must be `Codable` (for `codable: true` restoration)
/// and `Hashable`.
enum TaskSource: Codable, Hashable, Sendable {
    case list(TodoList)
    case smart(SmartList)

    var title: String {
        switch self {
        case .list(let list): list.name
        case .smart(let smart): smart.name
        }
    }

    var symbol: String {
        switch self {
        case .list(let list): list.symbol
        case .smart(let smart): smart.symbol
        }
    }

    /// The list a task created from this screen should land in — smart
    /// filters have no container of their own, so they fall back.
    func destinationListID(fallback: TodoList.ID) -> TodoList.ID {
        switch self {
        case .list(let list): list.id
        case .smart: fallback
        }
    }
}
