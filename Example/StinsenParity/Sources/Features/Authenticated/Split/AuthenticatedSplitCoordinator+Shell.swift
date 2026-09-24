import SwiftUI
import Scaffolding

// MARK: - Modals

extension AuthenticatedSplitCoordinator {
    /// The awaited-presentation showcase, from a split coordinator this
    /// time: `present(_:awaiting:)` suspends until the sheet closes and
    /// yields whatever it returned — `nil` when the user swiped it away.
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
            openTodo(id: created.id)
            toasts.show("Added “\(created.name)”", symbol: "plus.circle.fill")
        }
    }
}

// MARK: - AuthenticatedShell

extension AuthenticatedSplitCoordinator: AuthenticatedShell {
    var location: String { "detail column · \(section.rawValue)" }

    func openTodo(id: UUID) {
        if section == .todos {
            open(id: id)
        } else {
            show(.todos, task: id)
        }
    }

    func openTodo(named name: String) {
        guard let todo = store.todo(named: name) else {
            toasts.showWarning("No task called “\(name)”")
            return
        }
        openTodo(id: todo.id)
        toasts.show("Opened “\(todo.name)”", symbol: "link")
    }
}
