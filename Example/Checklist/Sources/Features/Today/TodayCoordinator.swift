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
    // The route table: one line per destination, with the bodies in
    // TodayCoordinator+Factory.swift. These declarations have to stay in the class
    // body — @Scaffoldable scans only the class declaration, so a route
    // moved to an extension is silently untracked.

    func today() -> some View { makeToday() }

    func todo(todo: Todo) -> any Coordinatable { makeTodo(todo: todo) }

    func newTodo(source: TaskSource) -> any Coordinatable { makeNewTodo(source: source) }

    func focus() -> some View { makeFocus() }
}
