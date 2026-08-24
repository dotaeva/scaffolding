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
                Image(systemName: todo.isDone ? "largecircle.fill.circle" : "circle")
                    .font(.title3)
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(todo.isDone ? "Mark as not done" : "Mark as done")

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    if let marker = todo.priority.marker {
                        Text(marker)
                            .foregroundStyle(todo.priority.tint)
                            .fontWeight(.semibold)
                    }
                    Text(todo.title)
                        .strikethrough(todo.isDone, color: .secondary)
                        .foregroundStyle(todo.isDone ? .secondary : .primary)
                }
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(todo.isOverdue ? .red : .secondary)
                }
            }

            Spacer(minLength: 0)

            if todo.isFlagged {
                Image(systemName: "flag.fill")
                    .foregroundStyle(.orange)
                    .font(.caption)
            }
        }
    }

    private var subtitle: String? {
        [listName, todo.dueDescription]
            .compactMap { $0 }
            .joined(separator: " · ")
            .nilIfEmpty
    }
}

extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
