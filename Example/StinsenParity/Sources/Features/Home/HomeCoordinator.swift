import SwiftUI
import Scaffolding

/// A one-screen flow. It stays a `FlowCoordinatable` rather than a bare
/// view so the tab has a stack to push into later — and so re-tapping the
/// tab has something to pop.
@MainActor
@Observable
@Scaffoldable
final class HomeCoordinator: @MainActor FlowCoordinatable {
    var stack = FlowStack<HomeCoordinator>(root: .home)

    let store: TodosStore

    init(store: TodosStore) {
        self.store = store
    }

    // MARK: Routes

    func home() -> some View { makeHome() }
}

// MARK: - Cross-section navigation

extension HomeCoordinator {
    /// A favourite tapped on Home opens in the Todos section. That is the
    /// *shell's* business, so this hops up to it rather than trying to
    /// route across a boundary it doesn't own — and it asks for the shell
    /// by role, so the same call switches a tab on iPhone and swaps two
    /// columns on iPad.
    func openInTodos(_ todo: Todo) {
        authenticatedShell()?.openTodo(id: todo.id)
    }
}
