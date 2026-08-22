import SwiftUI
import Scaffolding

/// The presented order sub-flow: multiple steps inside one sheet.
@MainActor
@Observable
@Scaffoldable
final class OrderCoordinator: @MainActor FlowCoordinatable {
    var stack = FlowStack<OrderCoordinator>(root: .amount)

    let holding: Holding
    var shares = 1
    private let onComplete: @MainActor (Order) -> Void

    init(holding: Holding, onComplete: @escaping @MainActor (Order) -> Void) {
        self.holding = holding
        self.onComplete = onComplete
    }

    // MARK: Routes
    // Routes must be declared in the class body — @Scaffoldable scans only
    // the class declaration, never extensions.

    func amount() -> some View { OrderAmountScreen() }
    func review() -> some View { OrderReviewScreen() }
    func confirmation(order: Order) -> some View { OrderConfirmationScreen(order: order) }
}

// MARK: - Navigation

extension OrderCoordinator {
    func goToReview() {
        route(to: .review)
    }

    /// replaceLast: the review screen is swapped for the confirmation, so
    /// back can't return to a review of an already-placed order.
    func confirm() {
        let order = Order(holding: holding, shares: shares)
        onComplete(order)
        replaceLast(with: .confirmation(order: order))
    }

    /// setRoot on a flow clears every pushed destination first — back at the
    /// amount screen with a fresh stack.
    func startOver() {
        shares = 1
        setRoot(.amount)
    }

    /// Closes the whole sheet. pop() would only remove the top screen —
    /// the two are not interchangeable.
    func close() {
        dismissCoordinator()
    }
}
