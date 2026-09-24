import SwiftUI
import Scaffolding

/// The Todos tab: a list, a pushed detail, and a presented "create"
/// sub-flow that hands a `Todo` back.
@MainActor
@Observable
@Scaffoldable
final class TodosCoordinator: @MainActor FlowCoordinatable {
    var stack = FlowStack<TodosCoordinator>(root: .todos)

    let store: TodosStore
    let toasts: ToastCenter

    init(store: TodosStore, toasts: ToastCenter) {
        self.store = store
        self.toasts = toasts
    }

    // MARK: Routes

    func todos() -> some View { makeTodos() }

    func todo(id: UUID) -> some View { makeTodo(id: id) }

    /// A child coordinator rather than a view-only sheet, because it
    /// returns a value.
    func createTodo() -> any Coordinatable { makeCreateTodo() }
}
