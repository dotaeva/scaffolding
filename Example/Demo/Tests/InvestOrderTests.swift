import Testing
import Scaffolding
import ScaffoldingTesting
@testable import Demo

/// Cross-coordinator results: a presented sub-flow hands a value back to the
/// presenter, which reports it further up the tree.
@MainActor
@Suite("Invest orders")
struct InvestOrderTests {

    /// The tab tree, so `ancestor(ofType:)` inside the coordinators has
    /// something to find.
    private func makeTree() -> (MainTabCoordinator, InvestCoordinator) {
        let tabs = MainTabCoordinator().activated()
        // Programmatic selection — bypasses the shouldSelect gate.
        let invest = tabs.selectFirstTab(.invest, expecting: InvestCoordinator.self)!
        return (tabs, invest)
    }

    @Test("starting an order presents a sub-flow with its own stack")
    func startOrderPresentsSubFlow() {
        let (_, invest) = makeTree()

        let order = invest.startOrder(for: Holding.samples[1])

        #expect(order != nil)
        #expect(invest.isPresentingModal)
        #expect(invest.depth == 0)
        #expect(order?.routeType == .sheet)
        #expect(order?.topDestination == .amount)
    }

    @Test("confirming delivers the order to the presenter and badges the tab")
    func resultTravelsUpTheTree() {
        let (tabs, invest) = makeTree()
        let order = invest.startOrder(for: Holding.samples[1])

        order?.shares = 3
        order?.goToReview()
        #expect(order?.topDestination == .review)

        order?.confirm()

        // The constructor callback ran: presenter state, then the badge the
        // presenter set on its own ancestor.
        #expect(invest.orders.count == 1)
        #expect(invest.orders.first?.shares == 3)
        #expect(tabs.badge(for: .invest) == "1")
    }

    @Test("replaceLast swaps the review out instead of stacking on it")
    func confirmReplacesReview() {
        let (_, invest) = makeTree()
        let order = invest.startOrder(for: Holding.samples[0])
        order?.goToReview()

        order?.confirm()

        #expect(order?.topDestination == .confirmation)
        #expect(order?.depth == 1)                 // review is gone, not buried
        #expect(order?.isInStack(.review) == false)
    }

    @Test("setRoot on a flow clears its pushes")
    func startOverResetsTheFlow() {
        let (_, invest) = makeTree()
        let order = invest.startOrder(for: Holding.samples[0])
        order?.shares = 5
        order?.goToReview()

        order?.startOver()

        #expect(order?.depth == 0)
        #expect(order?.topDestination == .amount)
        #expect(order?.shares == 1)
    }

    @Test("dismissCoordinator closes the whole sheet, not one screen")
    func closeDismissesTheSubFlow() {
        let (_, invest) = makeTree()
        let order = invest.startOrder(for: Holding.samples[0])
        order?.goToReview()

        order?.close()

        #expect(!invest.isPresentingModal)
    }

    @Test("the deep-link target pops before pushing the holding")
    func showHoldingResets() {
        let (_, invest) = makeTree()
        invest.openHolding(Holding.samples[0])
        invest.openHolding(Holding.samples[3])

        invest.showHolding(symbol: "NVDA")

        #expect(invest.depth == 1)
        #expect(invest.topDestination == .holding)
    }
}
