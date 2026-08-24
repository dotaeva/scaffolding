import Testing
import Scaffolding
import ScaffoldingTesting
@testable import Checklist

/// The playground's modal and awaited-navigation buttons.
@MainActor
@Suite("Playground modals")
struct PlaygroundModalTests {
    private func makeFlow() -> PlaygroundCoordinator {
        PlaygroundCoordinator().activated()
    }

    @Test("sheets and covers present with the presenter's configuration")
    func presentation() {
        let flow = makeFlow()

        flow.presentSheet()
        flow.presentSheet()          // .distinct — skipped
        #expect(flow.count(of: .sheet) == 1)

        flow.presentCover()
        #expect(flow.count(of: .cover) == 1)

        flow.dismissAllModals()
        #expect(!flow.isPresentingModal)
    }

    @Test("dismissModal closes the top modal and leaves pushes alone")
    func dismissModal() {
        let flow = makeFlow()
        flow.pushLeaf()
        flow.presentLockedSheet()

        flow.dismissModal()

        #expect(!flow.isPresentingModal)
        #expect(flow.depth == 1)
    }

    @Test("awaiting the picker records what it returned")
    func awaitedResult() async {
        let flow = makeFlow()

        flow.awaitPicker()
        await waitUntil { flow.isPresentingModal }
        flow.descendant(ofType: PlaygroundPickerCoordinator.self)?.pick(2)

        await waitUntil { flow.lastResult == "picker returned 2" }
        #expect(!flow.isPresentingModal)
    }

    @Test("cancelling the picker resumes with nil")
    func awaitedCancel() async {
        let flow = makeFlow()

        flow.awaitPicker()
        await waitUntil { flow.isPresentingModal }
        flow.descendant(ofType: PlaygroundPickerCoordinator.self)?.cancel()

        await waitUntil { flow.lastResult == "picker cancelled" }
    }

    @Test("routeAndWait resumes when the pushed leaf pops")
    func routeAndWait() async {
        let flow = makeFlow()

        flow.routeAndWaitLeaf()
        await waitUntil { flow.topDestination == .leaf }

        flow.pop()
        await waitUntil { flow.lastResult == "awaited leaf popped" }
        #expect(flow.depth == 0)
    }

    @Test("presentAndWait resumes when the sheet closes")
    func presentAndWait() async {
        let flow = makeFlow()

        flow.presentAndWaitSheet()
        await waitUntil { flow.isPresentingModal }

        flow.dismissModal()
        await waitUntil { flow.lastResult == "sheet dismissed" }
    }
}
