import Foundation
import Observation

/// Per-user todo storage, persisted to `UserDefaults` exactly like the
/// Stinsen demo's `TodosStore`.
@MainActor
@Observable
final class TodosStore {
    private(set) var all: [Todo] = []

    private let defaults: UserDefaults
    private let key: String

    var favorites: [Todo] { all.filter(\.isFavorite) }

    init(user: User, defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.key = "parity.todos.\(user.username)"

        if let data = defaults.data(forKey: key),
           let decoded = try? JSONDecoder().decode([Todo].self, from: data) {
            all = decoded
        } else {
            all = [Todo(name: "Read the migration guide"),
                   Todo(name: "Delete a NavigationStack", isFavorite: true)]
        }
    }

    subscript(id: UUID) -> Todo? {
        all.first { $0.id == id }
    }

    func todo(named name: String) -> Todo? {
        all.first { $0.name.lowercased() == name.lowercased() }
    }

    func add(_ todo: Todo) {
        all.append(todo)
        persist()
    }

    func toggleFavorite(_ id: UUID) {
        guard let index = all.firstIndex(where: { $0.id == id }) else { return }
        all[index].isFavorite.toggle()
        persist()
    }

    func delete(at offsets: IndexSet) {
        all.remove(atOffsets: offsets)
        persist()
    }

    private func persist() {
        defaults.set(try? JSONEncoder().encode(all), forKey: key)
    }
}
