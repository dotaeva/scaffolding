import Testing
import Scaffolding
import ScaffoldingTesting
@testable import Checklist

/// The playground exercises the whole navigation API, so its tests do too.
@MainActor
@Suite("Playground flow")
struct PlaygroundFlowTests {
    private func makeFlow() -> PlaygroundCoordinator {
        PlaygroundCoordinator().activated()
    }

    @Test("pushing chains, and .distinct guards a repeat of the same case")
    func pushes() {
        let flow = makeFlow()

        flow.push()
        flow.push()
        #expect(flow.count(of: .playground) == 2)

        flow.pushLeafDistinct()
        flow.pushLeafDistinct()   // same case on top — skipped
        #expect(flow.count(of: .leaf) == 1)
    }

    @Test("onDismiss counts the pushed leaves that leave")
    func onDismissCounts() {
        let flow = makeFlow()
        flow.pushLeaf()
        flow.pushLeaf()

        flow.popToRoot()

        #expect(flow.dismissals == 2)
    }

    @Test("replaceLast swaps the top; setRoot clears the stack")
    func replaceAndSetRoot() {
        let flow = makeFlow()
        flow.push()

        flow.replaceTop()
        #expect(flow.depth == 1)
        #expect(flow.topDestination == .leaf)

        flow.swapRoot()
        #expect(flow.depth == 0)
        #expect(flow.topDestination == .leaf)
        flow.restoreRoot()
        #expect(flow.topDestination == .playground)
    }

    @Test("meta-based pops aim at a case, popToRoot clears everything")
    func popFamily() {
        let flow = makeFlow()
        flow.pushLeaf()
        flow.push()
        flow.pushLeaf()
        #expect(flow.depth == 3)

        flow.popToFirst(.leaf)
        #expect(flow.depth == 1)      // back to the first leaf
        flow.popToRoot()
        #expect(flow.depth == 0)
    }

    @Test("a pushed child coordinator shares the stack and dismisses itself")
    func childCoordinator() {
        let flow = makeFlow()

        let child = flow.route(to: .child, expecting: PlaygroundChildCoordinator.self)?.activated()
        #expect(child != nil)
        #expect(child?.ancestor(ofType: PlaygroundCoordinator.self) === flow)

        child?.pushGrandchild()
        #expect(child?.depth == 1)

        child?.dismissCoordinator()   // the whole child, not one screen
        #expect(flow.depth == 0)
    }
}
