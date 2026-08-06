import SwiftUI
import Scaffolding

struct OrderConfirmationScreen: View {
    @Environment(OrderCoordinator.self) private var coordinator

    let order: Order

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 52))
                .foregroundStyle(.green)
            Text("Bought \(order.shares)× \(order.holding.symbol)")
                .font(.title3.weight(.semibold))
            Text(order.total, format: .currency(code: "USD"))
                .foregroundStyle(.secondary)
            Button("Done") {
                coordinator.close()
            }
            .buttonStyle(.pill)
            .padding(.horizontal, 60)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ScreenBackground())
        // This screen replaced the review via replaceLast — going back lands
        // on the amount screen, not the review.
    }
}
