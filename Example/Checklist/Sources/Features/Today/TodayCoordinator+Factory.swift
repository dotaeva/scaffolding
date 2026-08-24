import SwiftUI
import Scaffolding

// MARK: - Factory
// Where each route's screen is actually assembled: views get their
// ViewModels here, child coordinators get their dependencies. The
// route table stays in the class body because @Scaffoldable scans
// only the class declaration — a route in an extension is silently
// untracked — while these `make…` helpers are invisible to it, so
// they need no @ScaffoldingIgnored.

extension TodayCoordinator {
    func makeToday() -> some View {
        TodayView(viewModel: TodayViewModel(store: store))
    }

    /// Existential return ⇒ the macro tracks it as a child-coordinator
    /// destination. A concrete `-> TodoDetailCoordinator` would be skipped.
    func makeTodo(todo: Todo) -> any Coordinatable {
        TodoDetailCoordinator(todo: todo, store: store)
    }

    /// Modal sub-flow that hands back the task it created.
    func makeNewTodo(source: TaskSource) -> any Coordinatable {
        NewTodoCoordinator(source: source, store: store)
    }

    /// View-only modal presented as a cover (a sheet on macOS, which has
    /// no covers — the state still reports `.fullScreenCover`).
    func makeFocus() -> some View {
        FocusSessionView(todo: store.todos(in: .today).first)
    }
}
