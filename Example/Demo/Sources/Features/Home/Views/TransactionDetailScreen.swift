import SwiftUI
import Scaffolding

struct TransactionDetailScreen: View {
    @Environment(HomeCoordinator.self) private var coordinator

    let transaction: Transaction

    private var related: [Transaction] {
        Transaction.samples.filter { $0.category == transaction.category && $0.id != transaction.id }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                VStack(spacing: 14) {
                    Image(systemName: transaction.systemImage)
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 72, height: 72)
                        .background(.white.opacity(0.07), in: .circle)
                    Text(transaction.amount, format: .currency(code: "EUR").sign(strategy: .always()))
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(transaction.amount > 0 ? .green : .primary)
                    Text(transaction.category)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if !related.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        SectionTitle("Same category")
                        ForEach(related) { other in
                            Button {
                                // Recursive push of the same case — details
                                // stack up, and the pop controls below walk
                                // back through them.
                                coordinator.openRelated(other)
                            } label: {
                                TransactionRow(transaction: other)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                popControls
                StackInspector()
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
        }
        .scrollEdgeEffectStyle(.soft, for: .top)
        .background(ScreenBackground())
        .navigationTitle(transaction.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    /// Every pop variant. Pop-only controls appear once there's enough
    /// stack to act on.
    private var popControls: some View {
        VStack(spacing: 8) {
            SectionTitle("Pop variants")
            // pop() removes the top screen. (On an empty stack it would
            // dismiss the whole coordinator — not the case here.)
            ControlButton("pop()") { coordinator.pop() }
            if coordinator.depth >= 2 {
                // pop(n) removes up to n, always stopping at the root.
                ControlButton("pop(2)") { coordinator.pop(2) }
                ControlButton("popToRoot()") { coordinator.popToRoot() }
            }
            if coordinator.count(of: .transaction) >= 2 {
                // Meta-based: back to the first/last occurrence of the case.
                ControlButton("popToFirst(.transaction)") { coordinator.popToFirst(.transaction) }
                ControlButton("popToLast(.transaction)") { coordinator.popToLast(.transaction) }
            }
        }
    }
}

// Leaf view rendered alone: inject the coordinator it reads from
// @Environment. (\.destination is unreliable in previews — don't depend
// on routeType here.)
#Preview {
    TransactionDetailScreen(transaction: .samples[0])
        .environment(HomeCoordinator())
        .preferredColorScheme(.dark)
}
