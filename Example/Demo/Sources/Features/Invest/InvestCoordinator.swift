import SwiftUI
import Scaffolding

/// Result delivery via constructor callback. The buy route carries a closure
/// payload, so this coordinator can't opt into codable state restoration —
/// its subtree restores at the initial position, which is the documented
/// graceful fallback (capture on the rest of the tree still works).
@MainActor
@Observable
@Scaffoldable
final class InvestCoordinator: @MainActor GlassTabFlow {
    var stack = FlowStack<InvestCoordinator>(root: .portfolio)

    private(set) var orders: [Order] = []

    // MARK: Routes
    // Routes must be declared in the class body — @Scaffoldable scans only
    // the class declaration, never extensions.

    func portfolio() -> some View { InvestScreen().tabScreenFade() }
    func holding(holding: Holding) -> some View { HoldingDetailScreen(holding: holding) }

    /// Constructor callback: the presenter installs the result channel when
    /// the child is created; the child never learns who presented it.
    func buy(holding: Holding, onComplete: @escaping @MainActor (Order) -> Void) -> any Coordinatable {
        OrderCoordinator(holding: holding, onComplete: onComplete)
    }
}

// MARK: - Navigation

extension InvestCoordinator {
    func openHolding(_ holding: Holding) {
        route(to: .holding(holding: holding), policy: .distinct)
    }

    /// Returning the resolved child via `expecting:` costs nothing at the
    /// call site (`@discardableResult`) and gives tests a handle on the
    /// presented flow — an action that presents internally is otherwise a
    /// dead end for a unit test.
    @discardableResult
    func startOrder(for holding: Holding) -> OrderCoordinator? {
        present(.buy(holding: holding, onComplete: { [weak self] order in
            self?.complete(order)
        }), as: .sheet, expecting: OrderCoordinator.self)
    }

    private func complete(_ order: Order) {
        orders.append(order)
        // Reach up for the tab badge. Coordinators use ancestor(ofType:); views
        // would read MainTabCoordinator straight from @Environment.
        ancestor(ofType: MainTabCoordinator.self)?.setBadge(orders.count, for: .invest)
    }

    /// Deep-link target (scaffolding-demo://holding/NVDA).
    func showHolding(symbol: String) {
        guard let match = Holding.samples.first(where: { $0.symbol == symbol }) else { return }
        popToRoot()
        route(to: .holding(holding: match))
    }
}
