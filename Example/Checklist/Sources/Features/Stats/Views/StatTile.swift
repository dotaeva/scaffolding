import SwiftUI

/// A small metric tile. `contentTransition(.numericText())` animates the
/// digits when the underlying number changes.
struct StatTile: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.bold())
                .contentTransition(.numericText())
                .foregroundStyle(tint)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(.raisedBackground, in: .rect(cornerRadius: 10))
    }
}
