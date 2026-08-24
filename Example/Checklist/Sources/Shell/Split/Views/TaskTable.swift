#if os(macOS)
import SwiftUI

/// The Mac face of the task list: a real `Table` with sortable columns.
/// Same ViewModel, same selection intent — only the presentation differs.
struct TaskTable: View {
    @State var viewModel: TaskListViewModel
    var selection: Binding<Todo.ID?>
    let onSelect: (Todo) -> Void

    var body: some View {
        Table(viewModel.todos, selection: selection) {
            TableColumn("") { todo in
                Button {
                    viewModel.toggleDone(todo)
                } label: {
                    Image(systemName: todo.isDone ? "largecircle.fill.circle" : "circle")
                }
                .buttonStyle(.plain)
            }
            .width(20)
            TableColumn("Task", value: \.title)
            TableColumn("Due") { todo in
                Text(todo.dueDescription ?? "—")
                    .foregroundStyle(todo.isOverdue ? .red : .secondary)
            }
            TableColumn("Priority") { todo in
                Text(todo.priority.name)
                    .foregroundStyle(todo.priority.tint)
            }
        }
        .contextMenu(forSelectionType: Todo.ID.self) { ids in
            if let id = ids.first, let todo = viewModel.store.todo(id: id) {
                Button("Flag", systemImage: "flag") { viewModel.toggleFlag(todo) }
                Button("Delete", systemImage: "trash", role: .destructive) {
                    viewModel.delete(todo)
                }
            }
        }
        .onChange(of: selection.wrappedValue) { _, id in
            guard let id, let todo = viewModel.store.todo(id: id) else { return }
            onSelect(todo)
        }
    }
}
#endif
