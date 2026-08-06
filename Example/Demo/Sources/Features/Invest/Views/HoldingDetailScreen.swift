import SwiftUI
import Scaffolding

struct HoldingDetailScreen: View {
    @Environment(InvestCoordinator.self) private var coordinator

    let holding: Holding

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                VStack(spacing: 14) {
                    Text(holding.price, format: .currency(code: "USD"))
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                    Text(holding.change / 100, format: .percent.precision(.fractionLength(2)).sign(strategy: .always()))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(holding.change >= 0 ? .green : .red)
                }
                .padding(.top, 24)

                Button("Buy \(holding.symbol)") {
                    // Presents the OrderCoordinator sub-flow; the result
                    // comes back through the constructor callback.
                    coordinator.startOrder(for: holding)
                }
                .buttonStyle(.pill)
            }
            .padding(.horizontal, 20)
        }
        .scrollEdgeEffectStyle(.soft, for: .top)
        .background(ScreenBackground())
        .navigationTitle(holding.symbol)
        .navigationBarTitleDisplayMode(.inline)
    }
}
