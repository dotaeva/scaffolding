import Testing
import Foundation
import Scaffolding
import ScaffoldingTesting
@testable import StinsenParity

/// The reuse story: the same flows the tab shell hosts, hosted as columns,
/// plus the cross-section walks that have to work in both shells.
@MainActor
@Suite("Split shell")
struct SplitShellTests {
    private func makeSplit() -> AuthenticatedSplitCoordinator {
        AuthenticatedSplitCoordinator(user: .preview, toasts: ToastCenter()).activated()
    }

    @Test("the detail column hosts the same flows the tab shell does")
    func columnsHostTheTabFlows() {
        let split = makeSplit()

        split.select(.testbed)
        #expect(split.hierarchyContains(
            AuthenticatedSplitCoordinator.self, .testbed, as: .column(.detail)
        ))
        #expect(split.descendant(ofType: TestbedCoordinator.self) != nil)

        split.select(.profile)
        #expect(split.descendant(ofType: ProfileCoordinator.self) != nil)
    }

    @Test("a flow in a column pushes and pops like any other")
    func pushesInsideAColumn() {
        let split = makeSplit()
        split.select(.testbed)

        let testbed = split.descendant(ofType: TestbedCoordinator.self)
        testbed?.pushScreen()
        #expect(testbed?.depth == 1)

        testbed?.popToRoot()
        #expect(testbed?.depth == 0)
    }

    // MARK: Cross-section navigation

    @Test("opening a task from another section swaps both columns at once")
    func openTodoFromAnotherSection() {
        let split = makeSplit()
        let id = split.store.all[0].id

        split.openTodo(id: id)

        #expect(split.section == .todos)
        #expect(split.anySplitColumns.hasContentColumn)
        #expect(split.selectedTodoID == id)
        #expect(split.isDetail(.todo))
    }

    @Test("Home asks the shell by role, so the same call works in both")
    func homeReachesTheShell() {
        let split = makeSplit()
        split.select(.home)
        let home = split.descendant(ofType: HomeCoordinator.self)
        let todo = split.store.all[0]

        home?.openInTodos(todo)

        #expect(split.selectedTodoID == todo.id)
    }

    @Test("awaiting the create sub-flow lands the task in the detail column")
    func awaitedCreate() async {
        let split = makeSplit()
        let before = split.store.all.count

        split.addTodo()
        await waitUntil { split.isPresentingModal }
        split.descendant(ofType: CreateTodoCoordinator.self)?.create(name: "From a column")

        await waitUntil { split.store.all.count == before + 1 }
        #expect(!split.isPresentingModal)
        #expect(split.isDetail(.todo))
        #expect(split.store[split.selectedTodoID!]?.name == "From a column")
    }
}
