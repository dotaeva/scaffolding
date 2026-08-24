import SwiftUI
import Scaffolding

// MARK: - Pushes

extension TodayCoordinator {
    /// `.distinct` skips the push when the same case is already on top — a
    /// double tap while the push animates would otherwise stack twice.
    func open(_ todo: Todo) {
        route(to: .todo(todo: todo), policy: .distinct)
    }

    /// Same case pushed again on purpose (task → related task), so the
    /// default `.always` policy.
    func openAnother(_ todo: Todo) {
        route(to: .todo(todo: todo))
    }
}

// MARK: - Modals

extension TodayCoordinator {
    /// `present(_:awaiting:)` suspends until the sub-flow is dismissed and
    /// returns whatever it passed to `dismissCoordinator(returning:)`;
    /// cancel and swipe-down resume with `nil`.
    func addTodo() {
        Task {
            let created = await present(
                .newTodo(source: .smart(.today)),
                as: .sheet(detents: [.large]),
                awaiting: Todo.self
            )
            guard let created else { return }
            store.add(created)
            open(created)
        }
    }

    /// A full-screen cover, presented with `.distinct` so the button can't
    /// stack two of them.
    func startFocusSession() {
        present(.focus, as: .fullScreenCover, policy: .distinct)
    }
}
