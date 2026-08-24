import SwiftUI

/// The native gesture affordances every task row gets: swipe actions on
/// both edges and a context menu. Kept in one modifier so the four
/// list-shaped screens can't drift apart.
struct TodoRowActions: ViewModifier {
    let todo: Todo
    let toggleDone: () -> Void
    let toggleFlag: () -> Void
    let delete: () -> Void

    func body(content: Content) -> some View {
        content
            .swipeActions(edge: .leading) {
                Button(todo.isDone ? "Not Done" : "Done", systemImage: "checkmark.circle") {
                    toggleDone()
                }
                .tint(.green)
            }
            .swipeActions(edge: .trailing) {
                Button("Delete", systemImage: "trash", role: .destructive, action: delete)
                Button(todo.isFlagged ? "Unflag" : "Flag", systemImage: "flag", action: toggleFlag)
                    .tint(.orange)
            }
            .contextMenu {
                Button(todo.isDone ? "Mark as Not Done" : "Mark as Done",
                       systemImage: "checkmark.circle", action: toggleDone)
                Button(todo.isFlagged ? "Remove Flag" : "Flag",
                       systemImage: "flag", action: toggleFlag)
                Divider()
                Button("Delete", systemImage: "trash", role: .destructive, action: delete)
            }
    }
}

extension View {
    func todoRowActions(
        for todo: Todo,
        toggleDone: @escaping () -> Void,
        toggleFlag: @escaping () -> Void,
        delete: @escaping () -> Void
    ) -> some View {
        modifier(TodoRowActions(
            todo: todo,
            toggleDone: toggleDone,
            toggleFlag: toggleFlag,
            delete: delete
        ))
    }
}
