import Foundation

/// Named `Todo`, never `Task` — `Task` would shadow Swift concurrency's
/// `Task`, which the awaitable navigation APIs need.
struct Todo: Identifiable, Codable, Equatable, Hashable, Sendable {
    let id: UUID
    var name: String
    var isFavorite: Bool

    init(id: UUID = UUID(), name: String, isFavorite: Bool = false) {
        self.id = id
        self.name = name
        self.isFavorite = isFavorite
    }
}
