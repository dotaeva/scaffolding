import SwiftUI
import Scaffolding

struct TransactionsScreen: View {
    @Environment(HomeCoordinator.self) private var coordinator

    private var transactions: [Transaction] {
        guard let category = coordinator.category else { return Transaction.samples }
        return Transaction.samples.filter { $0.category == category }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Personal · EUR")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(.secondary)
                    Text(8_243.57, format: .currency(code: "EUR"))
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                }
                .padding(.top, 8)

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        SectionTitle("Transactions")
                        Button(coordinator.category ?? "All categories") {
                            // routeAndWait suspends until the picker pops;
                            // the filter is applied when this resumes.
                            Task { await coordinator.pickCategory() }
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                    ForEach(transactions) { transaction in
                        Button {
                            coordinator.open(transaction)
                        } label: {
                            TransactionRow(transaction: transaction)
                        }
                        .buttonStyle(.plain)
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
