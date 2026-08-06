import SwiftUI

struct IconRow: View {
    let title: String
    var subtitle: String? = nil
    let systemImage: String
    var trailing: String? = nil
    var trailingTint: Color = .primary

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 40, height: 40)
                .background(.white.opacity(0.07), in: .circle)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(trailingTint)
            } else {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 8)
        // Rows render inside Buttons — without this, the transparent gap
        // around the Spacer is a hit-test dead zone.
        .contentShape(.rect)
    }
}
