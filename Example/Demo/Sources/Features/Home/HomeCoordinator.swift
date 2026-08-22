import SwiftUI
import Scaffolding

/// Push/pop family: route policies, every pop variant, stack queries,
/// routeAndWait, and a seeded initial path.
@MainActor
@Observable
@Scaffoldable(codable: true)
final class HomeCoordinator: @MainActor GlassTabFlow {
    var stack: FlowStack<HomeCoordinator>

    /// Filter written by the category picker, awaited via routeAndWait.
    var category: String?

    /// FlowStack(root:pushing:) seeds pushed destinations when the stack is
    /// first set up — used by previews and deterministic starts. The macro
    /// synthesises no init(initialRoute:); write the initializer yourself.
    init(startingAt transaction: Transaction? = nil) {
        stack = transaction.map { FlowStack(root: .transactions, pushing: [.transaction(transaction: $0)]) }
            ?? FlowStack(root: .transactions)
    }

    // MARK: Routes
    // Routes must be declared in the class body — @Scaffoldable scans only
    // the class declaration, never extensions.

    func transactions() -> some View { TransactionsScreen().tabScreenFade() }
    func transaction(transaction: Transaction) -> some View {
        TransactionDetailScreen(transaction: transaction)
    }
    func categoryPicker() -> some View { CategoryPickerScreen() }
}

// MARK: - Navigation

extension HomeCoordinator {
    /// .distinct: a second tap while the push animates would double-push;
    /// the policy skips the route when the same case is already on top.
    /// onDismiss fires exactly once however the screen leaves the stack —
    /// pop, back swipe, popToRoot, tab re-tap, coordinator dismissal.
    func open(_ transaction: Transaction) {
        route(to: .transaction(transaction: transaction), policy: .distinct) {
            print("transaction detail dismissed")
        }
    }

    /// Same case pushed again on purpose (related-transaction chains), so
    /// the default .always policy.
    func openRelated(_ transaction: Transaction) {
        route(to: .transaction(transaction: transaction))
    }

    /// routeAndWait: push and suspend until the screen pops. The picker
    /// writes `category` and pops itself; this resumes afterwards.
    func pickCategory() async {
        await routeAndWait(to: .categoryPicker)
    }

    /// Deep-link target (scaffolding-demo://transaction/2).
    func showTransaction(id: Int) {
        guard let match = Transaction.samples.first(where: { $0.id == id }) else { return }
        popToRoot()
        route(to: .transaction(transaction: match))
    }
}

// Preview the coordinator at its real root…
#Preview("Home") {
    HomeCoordinator().view
        .preferredColorScheme(.dark)
}

// …or mid-flow via the seeded FlowStack(root:pushing:) initializer — there
// is no macro-made init(initialRoute:).
#Preview("Home · detail pushed") {
    HomeCoordinator(startingAt: Transaction.samples[1]).view
        .preferredColorScheme(.dark)
}
