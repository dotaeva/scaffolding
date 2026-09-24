import Testing
import Foundation
import Scaffolding
import ScaffoldingTesting
@testable import StinsenParity

/// The columns themselves: what `setContent`/`removeContent`/`setDetail`
/// do, and the two guards a split view needs that `RoutePolicy` can't give
/// it. `ShellLayout` is a value rather than a `#if`, so these run on any
/// device — including the iPhone simulator.
@MainActor
@Suite("Split columns")
struct SplitColumnTests {
    private func makeSplit() -> AuthenticatedSplitCoordinator {
        AuthenticatedSplitCoordinator(user: .preview, toasts: ToastCenter()).activated()
    }

    @Test("launches on Home with two columns")
    func launchesTwoColumn() {
        let split = makeSplit()

        #expect(split.sidebarDestination == .sidebar)
        #expect(split.isDetail(.home))
        #expect(!split.anySplitColumns.hasContentColumn)
    }

    @Test("selecting Todos installs the middle column, the others drop it")
    func todosOwnsTheContentColumn() {
        let split = makeSplit()

        split.select(.todos)
        #expect(split.anySplitColumns.hasContentColumn)
        #expect(split.contentDestination == .todos)
        #expect(split.isDetail(.noSelection))

        split.select(.profile)
        #expect(!split.anySplitColumns.hasContentColumn)
        #expect(split.isDetail(.profile))
    }

    @Test("re-selecting a section leaves its column alone")
    func reselectionIsGuarded() {
        let split = makeSplit()
        split.select(.testbed)
        let testbed = split.descendant(ofType: TestbedCoordinator.self)
        testbed?.pushScreen()

        split.select(.testbed)

        // A rebuilt column would be a fresh coordinator at depth 0.
        #expect(split.descendant(ofType: TestbedCoordinator.self) === testbed)
        #expect(testbed?.depth == 1)
    }

    @Test("switching between two tasks is not swallowed by the case guard")
    func taskSwitchIsNotDistinct() {
        let split = makeSplit()
        split.select(.todos)
        let ids = split.store.all.map(\.id)

        split.open(id: ids[0])
        #expect(split.selectedTodoID == ids[0])

        // Both resolve to the same `.todo` case, which is exactly what
        // RoutePolicy.distinct would have swallowed.
        split.open(id: ids[1])
        #expect(split.selectedTodoID == ids[1])
        #expect(split.isDetail(.todo))
    }
}
