import Testing
import Foundation
import Scaffolding
import ScaffoldingTesting
@testable import Demo

/// Modals: presentation, presenter-side dismissal, and the awaitable API.
@MainActor
@Suite("Cards modals")
struct CardsModalTests {

    @Test("presenting a sheet leaves the push stack untouched")
    func modalIsNotAPush() {
        let cards = CardsCoordinator().activated()

        cards.openDetail(Card.samples[0])

        #expect(cards.isPresentingModal)
        #expect(cards.depth == 0)              // modals are not pushes
        #expect(cards.topDestination == .cards)
    }

    @Test("RoutePolicy.distinct keeps one copy of the same sheet")
    func distinctPolicySkipsDuplicateSheet() {
        let cards = CardsCoordinator().activated()
        let card = Card.samples[0]

        cards.openDetail(card)
        cards.openDetail(card)

        #expect(cards.count(of: .cardDetail) == 1)
    }

    @Test("answering the freeze prompt writes state and closes the sheet")
    func resolveFreezeDismisses() {
        let cards = CardsCoordinator().activated()
        let card = Card.samples[0]
        cards.askFreeze(card)
        #expect(cards.isPresentingModal)

        cards.resolveFreeze(card, freeze: true)

        #expect(cards.frozen.contains(card.id))
        #expect(!cards.isPresentingModal)
    }

    @Test("dismissModal is a no-op when nothing is presented")
    func dismissModalIsSafe() {
        let cards = CardsCoordinator().activated()
        cards.route(to: .pinChange)   // a push, not a modal

        cards.dismissModal()

        #expect(cards.depth == 1)     // pop() would have removed this
    }

    @Test("a presented flow pushes inside itself, not into the presenter")
    func presentedFlowOwnsItsStack() {
        let cards = CardsCoordinator().activated()

        // `expecting:` is the test seam for child coordinators: it performs
        // the navigation and hands back the resolved child, typed.
        let picker = cards.present(.limitPicker, expecting: LimitCoordinator.self)

        #expect(picker != nil)
        picker?.openCustom()

        #expect(picker?.depth == 1)            // pushed inside the sheet
        #expect(cards.depth == 0)              // presenter's stack untouched
        #expect(picker?.routeType == .sheet)   // how the child was presented
        #expect(picker?.ancestor(ofType: CardsCoordinator.self) === cards)
    }

    @Test("dismissCoordinator(returning:) closes the sheet from the inside")
    func childDismissesItself() {
        let cards = CardsCoordinator().activated()
        let picker = cards.present(.limitPicker, expecting: LimitCoordinator.self)

        picker?.finish(2_000)

        #expect(!cards.isPresentingModal)
    }

    @Test("present(_:awaiting:) resumes with nil when the user backs out")
    func awaitingResumesWithNilOnDismissal() async {
        let cards = CardsCoordinator().activated()

        let picking = Task { await cards.present(.limitPicker, awaiting: Decimal.self) }
        await waitUntil { cards.isPresentingModal }

        cards.dismissModal()          // stands in for a swipe-down

        #expect(await picking.value == nil)
        #expect(cards.limit == 1_500) // unchanged
    }

    @Test("presentAndWait resumes after the presenter closes the cover")
    func presentAndWaitResumes() async {
        let cards = CardsCoordinator().activated()

        cards.changePin()             // wraps presentAndWait in a Task
        await waitUntil { cards.isPresentingModal }

        cards.dismissModal()

        await waitUntil { cards.toast == "PIN updated" }
        #expect(!cards.isPresentingModal)
    }

    @Test("a modal with no controls can only be closed by the presenter")
    func processingOverlayIsPresenterOwned() {
        let cards = CardsCoordinator().activated()

        cards.orderReplacement()
        cards.orderReplacement()      // guarded by isPresentingModal

        #expect(cards.count(of: .processing) == 1)
    }
}
