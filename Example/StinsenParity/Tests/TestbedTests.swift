import Testing
import Foundation
import Scaffolding
import ScaffoldingTesting
@testable import StinsenParity

@MainActor
@Suite("Testbed")
struct TestbedTests {
    private func makeTestbed() -> TestbedCoordinator {
        TestbedCoordinator(toasts: ToastCenter()).activated()
    }

    @Test("pushing grows the stack")
    func pushGrows() {
        let testbed = makeTestbed()

        testbed.pushScreen()
        testbed.pushScreen()

        #expect(testbed.depth == 2)
        #expect(testbed.count(of: .screen) == 2)
        #expect(testbed.topDestination == .screen)
    }

    @Test(".distinct swallows the second tap of the same case")
    func distinctGuardsDoubleTap() {
        let testbed = makeTestbed()

        testbed.pushDistinct()
        testbed.pushDistinct()

        #expect(testbed.depth == 1)
    }

    @Test("onDismiss fires exactly once per popped screen")
    func onDismissCountsRemovals() {
        let testbed = makeTestbed()
        testbed.pushScreen()
        testbed.pushScreen()

        testbed.popToRoot()

        #expect(testbed.dismissals == 2)
        #expect(testbed.depth == 0)
    }

    @Test("a child testbed is a generation deeper")
    func childIsDeeper() {
        let testbed = makeTestbed()

        testbed.pushChild()

        let child = testbed.descendant(ofType: TestbedCoordinator.self)
        #expect(child?.generation == 2)
    }

    @Test("dismissAllModals clears every queued sheet at once")
    func dismissAllModalsClearsBoth() {
        let testbed = makeTestbed()

        testbed.presentStackedSheets()
        #expect(testbed.isPresentingModal)

        testbed.dismissAllModals()

        #expect(!testbed.isPresentingModal)
        // Pushed destinations are never touched by a modal dismissal.
        #expect(testbed.depth == 0)
    }

    @Test("a tab's root coordinator cannot dismiss itself")
    func rootCannotDismissItself() {
        let testbed = makeTestbed()

        #expect(!testbed.canDismissSelf)
    }
}
