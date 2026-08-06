import SwiftUI

struct PaymentCard: View {
    let card: Card
    var frozen = false

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: "wave.3.right")
                    .font(.title3)
                Spacer()
                if frozen {
                    Label("Frozen", systemImage: "snowflake")
                        .font(.caption.weight(.semibold))
                }
            }
            Spacer()
            Text(card.holder)
                .font(.caption.weight(.semibold))
                .opacity(0.85)
            Text("•••• \(card.suffix)")
                .font(.callout.weight(.semibold))
                .monospacedDigit()
        }
        .foregroundStyle(.white)
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 190)
        .background(
            LinearGradient(colors: card.design.colors, startPoint: .topLeading, endPoint: .bottomTrailing),
            in: .rect(cornerRadius: 20)
        )
        .saturation(frozen ? 0.2 : 1)
    }
}

#Preview {
    VStack {
        PaymentCard(card: .samples[0])
        PaymentCard(card: .samples[1], frozen: true)
    }
    .padding()
    .background(ScreenBackground())
}
