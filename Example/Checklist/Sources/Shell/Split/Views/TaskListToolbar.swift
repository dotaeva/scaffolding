import SwiftUI

/// Shared toolbar for the task-list screens: add, plus the native view
/// options menu. Sorting and "show completed" are *domain* preferences, so
/// they live on the store.
struct TaskListToolbar: ToolbarContent {
    let store: TodoStore
    let onAdd: () -> Void

    var body: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button("New Task", systemImage: "plus", action: onAdd)
                .keyboardShortcut("n", modifiers: .command)
        }
        ToolbarItem(placement: .automatic) {
            Menu("View Options", systemImage: "ellipsis.circle") {
                Toggle("Sort by Due Date", isOn: sortBinding)
                Toggle("Show Completed", isOn: completedBinding)
            }
        }
        #if os(iOS)
        ToolbarItem(placement: .topBarLeading) {
            EditButton()
        }
        #endif
    }

    private var sortBinding: Binding<Bool> {
        Binding(get: { store.sortByDueDate }, set: { store.sortByDueDate = $0 })
    }

    private var completedBinding: Binding<Bool> {
        Binding(get: { store.showsCompleted }, set: { store.showsCompleted = $0 })
    }
}
