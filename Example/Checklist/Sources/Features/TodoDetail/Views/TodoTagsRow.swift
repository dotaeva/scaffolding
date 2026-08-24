import SwiftUI

/// Tag summary row that opens the picker sub-flow.
struct TodoTagsRow: View {
    let tags: [String]
    let edit: () -> Void

    var body: some View {
        Button(action: edit) {
            HStack {
                Text("Tags")
                    .foregroundStyle(.primary)
                Spacer()
                if tags.isEmpty {
                    Text("None")
                        .foregroundStyle(.secondary)
                } else {
                    HStack(spacing: 4) {
                        ForEach(tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.tint.opacity(0.15), in: .capsule)
                        }
                    }
                }
                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .buttonStyle(.plain)
    }
}
