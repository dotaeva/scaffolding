import SwiftUI
import Scaffolding

// MARK: - Actions

extension TodosCoordinator {
    /// `.distinct` guards the double-tap: the second tap is skipped
    /// because the same case is already on top.
    func open(id: UUID) {
        route(to: .todo(id: id), policy: .distinct)
    }

    /// The awaited-presentation showcase. `present(_:awaiting:)` suspends
    /// until the sheet closes and yields whatever it returned — `nil` when
    /// the user swiped it away, so cancelling costs no extra plumbing.
    func addTodo() {
        Task {
            let created = await present(
                .createTodo,
                as: .sheet,
                awaiting: Todo.self
            )

            guard let created else {
                toasts.showNeutral("New task cancelled")
                return
            }

            store.add(created)
            toasts.show("Added “\(created.name)”", symbol: "plus.circle.fill")
        }
    }

    func toggleFavorite(_ id: UUID) {
        store.toggleFavorite(id)
        guard let todo = store[id] else { return }
        if todo.isFavorite {
            toasts.show("“\(todo.name)” added to Home", symbol: "star.fill", tint: .yellow)
        } else {
            toasts.showNeutral("“\(todo.name)” removed from Home", symbol: "star.slash")
        }
    }
}
