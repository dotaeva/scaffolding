import SwiftUI
import Scaffolding

struct OrderAmountScreen: View {
    @Environment(OrderCoordinator.self) private var coordinator

    var body: some View {
        @Bindable var coordinator = coordinator
        VStack(spacing: 24) {
            Stepper(value: $coordinator.shares, in: 1...100) {
                Text("\(coordinator.shares) share\(coordinator.shares == 1 ? "" : "s")")
                    .font(.title3.weight(.semibold))
            }
            LabeledContent("Total") {
                Text(coordinator.holding.price * Decimal(coordinator.shares),
                     format: .currency(code: "USD"))
            }
            Button("Review") {
                coordinator.goToReview()
            }
            .buttonStyle(.pill)

            // The two routeTypes answer different questions: this screen is
            // the flow's root, while the flow itself was presented as a sheet.
            Text("destination: root · coordinator: \(String(describing: coordinator.routeType))")
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(20)
        .background(ScreenBackground())
        .navigationTitle("Buy \(coordinator.holding.symbol)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                // Whole-sheet close; pop() would only remove the top screen.
                Button("Cancel") { coordinator.close() }
            }
        }
    }
}
