import SwiftUI
import Scaffolding

/// The iPhone Today tab: the push/pop workhorse. Pushing a task pushes a
/// whole *child coordinator* (the same one the iPad shows in its detail
/// column) onto this stack.
@MainActor
@Observable
@Scaffoldable(codable: true)
final class TodayCoordinator: @MainActor FlowCoordinatable {
    var stack: FlowStack<TodayCoordinator>

    let store: TodoStore

    init(store: TodoStore) {
        self.store = store
        stack = FlowStack(root: .today)
    }

    /// `FlowStack(root:pushing:)` seeds pushed destinations when the stack
    /// is first set up — for mid-flow previews and deterministic starts.
    /// The macro synthesises no `init(initialRoute:)`; write it yourself.
    init(store: TodoStore, startingAt todo: Todo) {
        self.store = store
        stack = FlowStack(root: .today, pushing: [.todo(todo: todo)])
    }

    // MARK: Routes

    func today() -> some View {
        TodayView(viewModel: TodayViewModel(store: store))
    }

    /// Existential return ⇒ the macro tracks it as a child-coordinator
    /// destination. A concrete `-> TodoDetailCoordinator` would be skipped.
    func todo(todo: Todo) -> any Coordinatable {
        TodoDetailCoordinator(todo: todo, store: store)
    }

    /// Modal sub-flow that hands back the task it created.
    func newTodo(source: TaskSource) -> any Coordinatable {
        NewTodoCoordinator(source: source, store: store)
    }

    /// View-only modal presented as a cover (a sheet on macOS, which has
    /// no covers — the state still reports `.fullScreenCover`).
    func focus() -> some View {
        FocusSessionView(todo: store.todos(in: .today).first)
    }
}
