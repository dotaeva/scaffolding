import SwiftUI
import Scaffolding

/// One task's detail. Deliberately shell-agnostic: it is **pushed** onto a
/// tab's stack on iPhone and **installed in the detail column** on
/// iPad/Mac. Same coordinator, two placements, no conditional code — a
/// flow in a split column simply builds its own `NavigationStack` there.
@MainActor
@Observable
@Scaffoldable(codable: true)
final class TodoDetailCoordinator: @MainActor FlowCoordinatable {
    var stack: FlowStack<TodoDetailCoordinator>

    let store: TodoStore

    init(todo: Todo, store: TodoStore) {
        self.store = store
        stack = FlowStack(root: .detail(todo: todo))
    }

    // MARK: Routes
    // The route table: one line per destination, with the bodies in
    // TodoDetailCoordinator+Factory.swift. These declarations have to stay in the class
    // body — @Scaffoldable scans only the class declaration, so a route
    // moved to an extension is silently untracked.

    func detail(todo: Todo) -> some View { makeDetail(todo: todo) }

    func notes(todo: Todo) -> some View { makeNotes(todo: todo) }

    func tagPicker(selected: [String]) -> any Coordinatable { makeTagPicker(selected: selected) }
}

// MARK: - Navigation

extension TodoDetailCoordinator {
    func editNotes(for todo: Todo) {
        route(to: .notes(todo: todo), policy: .distinct)
    }

    /// A flow-level `setRoot`: the next task replaces this one and the
    /// pushed stack is cleared, so "back" never returns to a task the user
    /// has moved on from.
    func showNext(after todo: Todo) {
        let siblings = store.todos.filter { $0.listID == todo.listID && !$0.isDone }
        guard let index = siblings.firstIndex(where: { $0.id == todo.id }),
              let next = siblings[safe: index + 1] ?? siblings.first,
              next.id != todo.id
        else { return }
        setRoot(.detail(todo: next))
    }

    /// `present(_:awaiting:)` again — this time the sub-flow returns tags.
    func pickTags(for todo: Todo) {
        Task {
            let picked = await present(
                .tagPicker(selected: todo.tags),
                as: .sheet(detents: [.medium]),
                awaiting: [String].self
            )
            guard let picked else { return }
            var updated = todo
            updated.tags = picked
            store.update(updated)
        }
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
