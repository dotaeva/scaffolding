import SwiftUI
import Scaffolding

/// The task list: the Todos tab's root on iPhone, the split view's middle
/// column on iPad and Mac.
///
/// It takes its navigation intents as closures instead of reading a
/// coordinator from the environment, because two different coordinators
/// own it — one pushes the task, the other replaces a column — and the
/// screen must not know which. Screens with a single owner (``TestbedScreen``,
/// ``HomeScreen``) read `@Environment` directly.
struct TodosScreen: View {
    let store: TodosStore
    /// Drives the native row highlight where a selection is meaningful —
    /// the split view's middle column. The tab pushes instead, so it
    /// passes a constant and rows never latch.
    var selection: Binding<UUID?> = .constant(nil)
    var onSelect: (UUID) -> Void = { _ in }
    var onAdd: () -> Void = { }

    var body: some View {
        content
            .navigationTitle("Todos")
            .navigationSplitViewColumnWidth(min: 260, ideal: 320, max: 420)
            .overlay {
                if store.all.isEmpty {
                    ContentUnavailableView(
                        "No tasks",
                        systemImage: "checklist",
                        description: Text("Add one with the + button.")
                    )
                }
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("New task", systemImage: "plus", action: onAdd)
                }
            }
    }

    private var content: some View {
        List(selection: selection) {
            ForEach(store.all) { todo in
                Button {
                    onSelect(todo.id)
                } label: {
                    TodoRow(todo: todo)
                }
                .tag(todo.id)
            }
            .onDelete { store.delete(at: $0) }
        }
    }
}

private struct TodoRow: View {
    let todo: Todo

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: todo.isFavorite ? "star.fill" : "circle")
                .font(.system(size: todo.isFavorite ? 15 : 14))
                .foregroundStyle(todo.isFavorite ? AnyShapeStyle(Color.yellow)
                                                 : AnyShapeStyle(.tertiary))
                .frame(width: 22)

            Text(todo.name)
                .foregroundStyle(Color.primary)
                .lineLimit(2)

            Spacer(minLength: 6)

            Image(systemName: "chevron.right")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 5)
    }
}
