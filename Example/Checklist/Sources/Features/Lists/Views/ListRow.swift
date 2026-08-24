import SwiftUI

/// One list row: symbol, name, open count, and a native progress bar.
struct ListRow: View {
    let list: TodoList
    let openCount: Int
    let progress: Double

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: list.symbol)
                .font(.callout)
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(list.color, in: .circle)
            VStack(alignment: .leading, spacing: 4) {
                Text(list.name)
                ProgressView(value: progress)
                    .tint(list.color)
                    .frame(maxWidth: 160)
            }
            Spacer()
            Text("\(openCount)")
                .font(.callout.weight(.medium))
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .padding(.vertical, 2)
    }
}
