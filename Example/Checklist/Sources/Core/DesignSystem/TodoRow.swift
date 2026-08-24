import SwiftUI

/// One task row, shared by every list-shaped screen (Today, a list,
/// search results). Native `List` row anatomy: leading toggle button,
/// title + metadata, trailing badges — no custom chrome.
struct TodoRow: View {
    let todo: Todo
    let listName: String?
    let toggle: () -> Void

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Button(action: toggle) {
                Image(systemName: todo.isDone ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(todo.isDone ? Color.accentColor : .secondary)
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(todo.isDone ? "Mark as not done" : "Mark as done")

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    if todo.priority != .none {
                        // A quiet dot carries priority; "!!!" shouted.
                        Circle()
                            .fill(todo.priority.tint)
                            .frame(width: 7, height: 7)
                            .accessibilityLabel("\(todo.priority.name) priority")
                    }
                    Text(todo.title)
                        .strikethrough(todo.isDone, color: .secondary)
                        .foregroundStyle(todo.isDone ? .secondary : .primary)
                }
                // Only the date turns red when it is overdue — the list
                // name is not the alarming part.
                HStack(spacing: 4) {
                    if let listName {
                        Text(listName)
                            .foregroundStyle(.secondary)
                        if todo.dueDescription != nil {
                            Text("·").foregroundStyle(.tertiary)
                        }
                    }
                    if let due = todo.dueDescription {
                        Text(due)
                            .foregroundStyle(todo.isOverdue ? .red : .secondary)
                    }
                }
                .font(.caption)
            }

            Spacer(minLength: 0)

            if todo.isFlagged {
                Image(systemName: "flag.fill")
                    .foregroundStyle(.orange)
                    .font(.caption)
            }
        }
    }

}

extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
