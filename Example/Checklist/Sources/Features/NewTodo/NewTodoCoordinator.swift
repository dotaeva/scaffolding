import SwiftUI
import Scaffolding

/// Modal sub-flow whose whole job is returning a value: compose → (pushed)
/// list picker → back, then `dismissCoordinator(returning:)` hands the new
/// task to the awaiting presenter.
///
/// Deliberately **not** `codable:` — whole-tree restoration records this
/// modal without its internal state, which is the graceful-degradation
/// path worth showing.
@MainActor
@Observable
@Scaffoldable
final class NewTodoCoordinator: @MainActor FlowCoordinatable {
    var stack = FlowStack<NewTodoCoordinator>(root: .compose)

    /// The flow owns the draft and injects it into both of its screens —
    /// this is state of the *flow*, not of one view.
    let draft: NewTodoViewModel

    init(source: TaskSource, store: TodoStore) {
        draft = NewTodoViewModel(source: source, store: store)
    }

    // MARK: Routes
    // The route table: one line per destination, with the bodies in
    // NewTodoCoordinator+Factory.swift. These declarations have to stay in the class
    // body — @Scaffoldable scans only the class declaration, so a route
    // moved to an extension is silently untracked.

    func compose() -> some View { makeCompose() }
    func listPicker() -> some View { makeListPicker() }
}

// MARK: - Chrome

extension NewTodoCoordinator {
    /// Always presented modally, so it always needs a Mac sheet size —
    /// the pushed list picker inherits it.
    func customize(_ view: AnyView) -> some View {
        view.sheetSizing(minHeight: 480)
    }
}

// MARK: - Steps

extension NewTodoCoordinator {
    /// `routeAndWait` pushes the picker and suspends until it pops —
    /// however it pops: its own row tap, the back button, or a swipe.
    func chooseList() {
        Task {
            await routeAndWait(to: .listPicker, policy: .distinct)
            draft.didReturnFromPicker()
        }
    }

    func save() {
        guard let todo = draft.build() else { return }
        dismissCoordinator(returning: todo)
    }

    func cancel() {
        dismissCoordinator()
    }
}
