import SwiftUI
import Scaffolding

struct OrderReviewScreen: View {
    @Environment(OrderCoordinator.self) private var coordinator

    var body: some View {
        VStack(spacing: 20) {
            LabeledContent("Holding", value: coordinator.holding.name)
            LabeledContent("Shares", value: "\(coordinator.shares)")
            LabeledContent("Total") {
                Text(coordinator.holding.price * Decimal(coordinator.shares),
                     format: .currency(code: "USD"))
            }
            Button("Confirm order") {
                // Delivers the order via the constructor callback, then
                // replaceLast swaps this screen for the confirmation —
                // back can't return to the review of a placed order.
                coordinator.confirm()
            }
            .buttonStyle(.pill)
            Button("Start over") {
                // setRoot on a flow: clears everything pushed first.
                coordinator.startOver()
            }
            Spacer()
        }
        .padding(20)
        .background(ScreenBackground())
        .navigationTitle("Review")
        .navigationBarTitleDisplayMode(.inline)
    }
}
