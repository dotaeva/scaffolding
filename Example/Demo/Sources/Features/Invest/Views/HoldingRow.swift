import SwiftUI

struct HoldingRow: View {
    let holding: Holding

    var body: some View {
        HStack(spacing: 14) {
            Text(holding.symbol.prefix(2))
                .font(.footnote.weight(.bold))
                .frame(width: 40, height: 40)
                .background(.white.opacity(0.07), in: .circle)
            VStack(alignment: .leading, spacing: 2) {
                Text(holding.symbol)
                    .font(.subheadline.weight(.semibold))
                Text(holding.name)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(holding.price, format: .currency(code: "USD"))
                    .font(.subheadline.weight(.medium))
                Text(holding.change / 100, format: .percent.precision(.fractionLength(2)).sign(strategy: .always()))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(holding.change >= 0 ? .green : .red)
            }
        }
        .padding(.vertical, 8)
        .contentShape(.rect)
    }
}
