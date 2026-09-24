import Testing
import Foundation
import Scaffolding
import ScaffoldingTesting
@testable import StinsenParity

/// A root swap destroys the screen that triggered it. These pin down that
/// the way back survives, because the bug is invisible from the coordinator
/// alone — the state is fine, it is the *reachable UI* that vanishes.
@MainActor
@Suite("Testbed root swap")
struct RootSwapTests {
    private func makeTestbed() -> TestbedCoordinator {
        TestbedCoordinator(toasts: ToastCenter()).activated()
    }

    @Test("swapping the root replaces the testbed")
    func swapReplacesRoot() {
        let testbed = makeTestbed()

        testbed.swapRoot()

        #expect(testbed.topDestination == .screen)
        #expect(testbed.depth == 0)
        #expect(testbed.isRootSwapped)
    }

    @Test("the swapped-in root reports that it can restore")
    func swappedRootOffersTheWayBack() {
        let testbed = makeTestbed()
        #expect(!testbed.isRootSwapped)

        testbed.swapRoot()

        // What the leaf screen reads to decide whether to show the
        // restore button instead of a useless "Back".
        #expect(testbed.isRootSwapped)
    }

    @Test("restoring brings the testbed back")
    func restoreReturnsToTheTestbed() {
        let testbed = makeTestbed()
        testbed.swapRoot()

        testbed.restoreRoot()

        #expect(testbed.topDestination == .testbed)
        #expect(!testbed.isRootSwapped)
    }

    @Test("the swap toast carries an undo that restores the testbed")
    func swapToastUndoRestores() {
        let toasts = ToastCenter()
        let testbed = TestbedCoordinator(toasts: toasts).activated()

        testbed.swapRoot()

        // The toast is the immediate escape hatch: it outlives the screen
        // that was torn down and draws above whatever replaced it.
        let undo = toasts.queue.last?.action
        #expect(undo != nil)
        undo?.perform()

        #expect(testbed.topDestination == .testbed)
        #expect(!testbed.isRootSwapped)
    }

    @Test("a pushed screen above a swapped root is not mistaken for the root")
    func pushedScreenIsNotTheSwappedRoot() {
        let testbed = makeTestbed()
        testbed.swapRoot()

        testbed.pushScreen()

        // Depth > 0, so this leaf offers a normal Back, not the restore.
        #expect(!testbed.isRootSwapped)

        testbed.popToRoot()
        #expect(testbed.isRootSwapped)
    }
}
