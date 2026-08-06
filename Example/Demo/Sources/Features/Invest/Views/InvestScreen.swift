import SwiftUI
import Scaffolding

struct InvestScreen: View {
    @Environment(InvestCoordinator.self) private var coordinator

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 4) {
                    SectionTitle("Portfolio")
                    ForEach(Holding.samples) { holding in
                        Button {
                            coordinator.openHolding(holding)
                        } label: {
                            HoldingRow(holding: holding)
                        }
                        .buttonStyle(.plain)
                    }
                }

                if !coordinator.orders.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        SectionTitle("Orders")
                        ForEach(coordinator.orders) { order in
                            IconRow(
                                title: "\(order.shares)× \(order.holding.symbol)",
                                subtitle: "Filled",
                                systemImage: "checkmark.circle",
                                trailing: order.total.formatted(.currency(code: "USD"))
                            )
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
        }
        .background(ScreenBackground())
        .statusBarScrim()
        .toolbar(.hidden, for: .navigationBar)
    }
}
