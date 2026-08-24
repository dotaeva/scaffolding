import Testing
import Foundation
import Scaffolding
import ScaffoldingTesting
@testable import Checklist

/// The playground's pop family, presenter-closed overlays, and
/// `dismissAllModals`.
@MainActor
@Suite("Settings flow")
struct SettingsFlowTests {
    private func makeFlow(store: TodoStore = TodoStore()) -> SettingsCoordinator {
        SettingsCoordinator(store: store).activated()
    }

    @Test("replaceLast swaps the top screen so back skips it")
    func replaceLast() {
        let flow = makeFlow()
        flow.showPlayground()
        #expect(flow.depth == 1)

        flow.replaceLast(with: .playground)

        #expect(flow.depth == 1)          // replaced, not stacked
        flow.pop()
        #expect(flow.depth == 0)
    }

    @Test("the same route can be pushed or presented")
    func pushOrPresent() {
        let flow = makeFlow()

        flow.showPlayground()
        flow.present(.playground, as: .sheet)

        #expect(flow.depth == 1)          // the push
        #expect(flow.isPresentingModal)   // and the modal, side by side
        #expect(flow.count(of: .playground) == 2)
    }

    @Test("the sync overlay is presenter-guarded and presenter-closed")
    func syncOverlay() async {
        let flow = makeFlow()

        flow.syncNow()
        flow.syncNow()                    // guarded: already presenting
        #expect(flow.count(of: .syncing) == 1)

        // The flow dismisses it itself once the fake work finishes. That is
        // a real one-second timer, so this waits on the clock rather than
        // on yields — waitUntil spins far faster than wall time.
        try? await Task.sleep(for: .milliseconds(1_400))
        #expect(!flow.isPresentingModal)
    }

    @Test("dismissAllModals clears modals but leaves the stack")
    func dismissAll() {
        let flow = makeFlow()
        flow.showAbout()
        flow.present(.playground, as: .sheet)
        flow.present(.tree, as: .fullScreenCover)

        flow.closeAllModals()

        #expect(!flow.isPresentingModal)
        #expect(flow.depth == 1)          // the pushed About stays
    }

    @Test("onDismiss fires when a presented modal is closed")
    func modalOnDismiss() {
        let flow = makeFlow()
        var dismissals = 0
        flow.present(.playground, as: .sheet, onDismiss: { dismissals += 1 })

        flow.dismissModal()
        flow.dismissModal()               // nothing up — safe no-op

        #expect(dismissals == 1)
    }

    @Test("tag management goes through the store")
    func tagManagement() {
        let store = TodoStore()
        let viewModel = SettingsViewModel(store: store)

        viewModel.newTag = "Weekend"
        viewModel.addTag()
        #expect(store.tags.contains("weekend"))   // normalised

        let index = store.tags.firstIndex(of: "urgent")!
        viewModel.deleteTags(at: IndexSet(integer: index))
        #expect(!store.tags.contains("urgent"))
        // …and the tag is gone from every task that used it.
        let noneTagged = store.todos.allSatisfy { !$0.tags.contains("urgent") }
        #expect(noneTagged)
    }
}
