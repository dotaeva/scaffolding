import SwiftUI
import Scaffolding

/// The task list, shown as the split view's middle column and as a pushed
/// screen in the Lists tab.
///
/// It takes its navigation intents as closures instead of reading a
/// coordinator from the environment: two different coordinators own it
/// (one replaces a column, the other pushes), and the screen shouldn't
/// know which. Screens with a single owner read `@Environment` directly.
struct TaskListView: View {
    @State var viewModel: TaskListViewModel
    /// Drives the native row highlight where a selection is meaningful —
    /// the split view's middle column. The tab shell pushes instead, so it
    /// passes a constant and rows never latch.
    var selection: Binding<Todo.ID?> = .constant(nil)
    var onSelect: (Todo) -> Void = { _ in }
    var onAdd: () -> Void = { }

    var body: some View {
        Group {
            #if os(macOS)
            TaskTable(viewModel: viewModel, selection: selection, onSelect: onSelect)
            #else
            list
            #endif
        }
        .navigationTitle(viewModel.title)
        // Wide enough for a title plus its list-and-date subtitle.
        .navigationSplitViewColumnWidth(min: 320, ideal: 380, max: 520)
        .toolbar { TaskListToolbar(store: viewModel.store, onAdd: onAdd) }
        .refreshable { await viewModel.sync() }
        .overlay {
            if viewModel.isEmpty {
                ContentUnavailableView(
                    "No Tasks",
                    systemImage: "checkmark.circle",
                    description: Text("Everything here is done. Add a task with the + button.")
                )
            }
        }
    }

    private var list: some View {
        List(selection: selection) {
            ForEach(viewModel.todos) { todo in
                Button { onSelect(todo) } label: {
                    TodoRow(todo: todo, listName: viewModel.listName(for: todo)) {
                        viewModel.toggleDone(todo)
                    }
                }
                .buttonStyle(.plain)
                .tag(todo.id)
                .todoRowActions(
                    for: todo,
                    toggleDone: { viewModel.toggleDone(todo) },
                    toggleFlag: { viewModel.toggleFlag(todo) },
                    delete: { viewModel.delete(todo) }
                )
            }
            .onDelete { viewModel.delete(at: $0) }
        }
    }
}
