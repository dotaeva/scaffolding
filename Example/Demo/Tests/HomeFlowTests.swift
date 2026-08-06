import Testing
import Scaffolding
import ScaffoldingTesting
@testable import Demo

/// Push/pop navigation on a `FlowCoordinatable`.
///
/// Everything here runs against the same `HomeCoordinator` the app ships —
/// no test double, no view, no simulator UI. The coordinator is the unit.
@MainActor
@Suite("Home flow")
struct HomeFlowTests {

    @Test("a fresh flow sits at its root")
    func startsAtRoot() {
        let home = HomeCoordinator().activated()

        #expect(home.depth == 0)
        #expect(home.topDestination == .transactions)
        #expect(!home.isPresentingModal)
    }

    @Test("opening a transaction pushes one screen")
    func openPushes() {
        let home = HomeCoordinator().activated()

        home.open(Transaction.samples[0])

        #expect(home.depth == 1)
        #expect(home.topDestination == .transaction)
        #expect(home.isInStack(.transaction))
    }

    @Test("RoutePolicy.distinct swallows a double tap")
    func distinctPolicySkipsDuplicatePush() {
        let home = HomeCoordinator().activated()
        let transaction = Transaction.samples[0]

        home.open(transaction)
        home.open(transaction)   // second tap while the push animates

        #expect(home.count(of: .transaction) == 1)
    }

    @Test("the default policy allows the same case twice")
    func relatedTransactionsStack() {
        let home = HomeCoordinator().activated()

        home.open(Transaction.samples[0])
        home.openRelated(Transaction.samples[1])
        home.openRelated(Transaction.samples[2])

        #expect(home.depth == 3)
        #expect(home.count(of: .transaction) == 3)
    }

    @Test("popToRoot clears every push")
    func popToRootClearsStack() {
        let home = HomeCoordinator().activated()
        home.open(Transaction.samples[0])
        home.openRelated(Transaction.samples[1])

        home.popToRoot()

        #expect(home.depth == 0)
        #expect(home.topDestination == .transactions)
        #expect(!home.isInStack(.transaction))
    }

    @Test("onDismiss fires exactly once, however the screen leaves")
    func onDismissFiresOnce() {
        let home = HomeCoordinator().activated()
        var dismissals = 0
        home.route(to: .transaction(transaction: Transaction.samples[0])) { dismissals += 1 }

        home.popToRoot()   // not pop() — the callback must still fire
        home.popToRoot()   // already at the root: no second call

        #expect(dismissals == 1)
    }

    @Test("FlowStack(root:pushing:) seeds a deep start")
    func seededPath() {
        // The same initializer the mid-flow #Preview uses — there is no
        // macro-generated init(initialRoute:).
        let home = HomeCoordinator(startingAt: Transaction.samples[1]).activated()

        #expect(home.depth == 1)
        #expect(home.topDestination == .transaction)
    }

    @Test("the deep-link target lands on a detail from any position")
    func deepLinkTargetResets() {
        let home = HomeCoordinator().activated()
        home.open(Transaction.samples[0])
        home.openRelated(Transaction.samples[3])

        home.showTransaction(id: 2)   // scaffolding-demo://transaction/2

        // popToRoot + one push — not four screens deep.
        #expect(home.depth == 1)
        #expect(home.topDestination == .transaction)
    }

    @Test("an unknown deep-link id leaves the stack alone")
    func deepLinkTargetIgnoresUnknownId() {
        let home = HomeCoordinator().activated()
        home.open(Transaction.samples[0])

        home.showTransaction(id: 999)

        #expect(home.depth == 1)
    }

    @Test("routeAndWait resumes when the pushed screen pops")
    func routeAndWaitResumes() async {
        let home = HomeCoordinator().activated()

        // pickCategory() suspends inside the coordinator until the picker
        // leaves the stack, so drive it from a task and pop for it.
        let picking = Task { await home.pickCategory() }
        await waitUntil { home.topDestination == .categoryPicker }

        home.category = "Groceries"   // what the picker screen writes
        home.pop()
        await picking.value

        #expect(home.depth == 0)
        #expect(home.category == "Groceries")
    }
}
