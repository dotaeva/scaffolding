import SwiftUI
import Scaffolding

// MARK: - Factory

extension TodosCoordinator {
    /// The shared list screen takes its intents as closures — here they
    /// push; in the split view's middle column they replace a column.
    func makeTodos() -> some View {
        TodosScreen(
            store: store,
            onSelect: { [weak self] id in self?.open(id: id) },
            onAdd: { [weak self] in self?.addTodo() }
        )
    }

    func makeTodo(id: UUID) -> some View {
        TodoScreen(
            store: store,
            id: id,
            onToggleFavorite: { [weak self] id in self?.toggleFavorite(id) }
        )
    }

    func makeCreateTodo() -> any Coordinatable { CreateTodoCoordinator() }
}
