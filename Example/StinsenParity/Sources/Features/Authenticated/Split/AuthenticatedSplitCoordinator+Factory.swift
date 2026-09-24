import SwiftUI
import Scaffolding

// MARK: - Factory
// Where each route's screen is actually assembled: views get their
// dependencies here, child coordinators get theirs. The route table stays
// in the class body because @Scaffoldable scans only the class
// declaration — a route in an extension is silently untracked — while
// these `make…` helpers are invisible to it, so they need no
// @ScaffoldingIgnored.

extension AuthenticatedSplitCoordinator {
    func makeSidebar() -> some View { ShellSidebar(user: user) }

    /// The middle column is the same list the Todos tab shows, handed
    /// column-shaped intents instead of push-shaped ones — which is the
    /// whole reason that screen takes its intents as closures.
    func makeTodos() -> some View {
        TodosScreen(
            store: store,
            selection: Binding(
                get: { [weak self] in self?.selectedTodoID },
                set: { [weak self] id in id.map { self?.open(id: $0) } }
            ),
            onSelect: { [weak self] id in self?.open(id: id) },
            onAdd: { [weak self] in self?.addTodo() }
        )
    }

    /// The detail column for a task. No coordinator: there is nothing to
    /// push from here, and a column is replaced rather than navigated.
    func makeTodo(id: UUID) -> some View {
        TodoScreen(
            store: store,
            id: id,
            onToggleFavorite: { [weak self] id in self?.toggleFavorite(id) }
        )
    }

    func makeNoSelection() -> some View {
        ContentUnavailableView {
            Label("No Task Selected", systemImage: "checklist")
        } description: {
            Text("Pick a task from the list, or add one with +.\n"
                 + "The detail column is replaced by setDetail(.todo(id:)) — "
                 + "not pushed onto anything.")
        } actions: {
            Button("New Task", systemImage: "plus") { self.addTodo() }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
        }
    }

    func makeHome() -> any Coordinatable { HomeCoordinator(store: store) }

    func makeProfile() -> any Coordinatable { ProfileCoordinator(user: user, store: store) }

    func makeTestbed() -> any Coordinatable { TestbedCoordinator(toasts: toasts) }

    func makeCreateTodo() -> any Coordinatable { CreateTodoCoordinator() }
}
