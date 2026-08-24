import Testing
import Scaffolding
import ScaffoldingTesting
@testable import Checklist

/// The detail flow and its tag-picker sub-flow, plus the ViewModel's
/// write-through editing.
@MainActor
@Suite("Task detail flow")
struct TodoDetailFlowTests {
    private func makeFlow(store: TodoStore = TodoStore()) -> TodoDetailCoordinator {
        TodoDetailCoordinator(todo: SampleData.todos[0], store: store).activated()
    }

    @Test("editing writes through to the store immediately")
    func writeThrough() {
        let store = TodoStore()
        let viewModel = TodoDetailViewModel(todo: SampleData.todos[0], store: store)

        viewModel.title = "Review PRs today"
        viewModel.priority = .low
        viewModel.isFlagged = false
        viewModel.hasDueDate = false

        let stored = store.todo(id: SampleData.todos[0].id)
        #expect(stored?.title == "Review PRs today")
        #expect(stored?.priority == .low)
        #expect(stored?.isFlagged == false)
        #expect(stored?.dueDate == nil)
    }

    @Test("notes push and pop inside the flow")
    func notesPush() {
        let flow = makeFlow()

        flow.editNotes(for: SampleData.todos[0])
        flow.editNotes(for: SampleData.todos[0])   // .distinct — skipped

        #expect(flow.count(of: .notes) == 1)
        flow.pop()
        #expect(flow.depth == 0)
    }

    @Test("next task swaps the flow's root and clears the stack")
    func nextTaskSetsRoot() {
        let flow = makeFlow()
        flow.editNotes(for: SampleData.todos[0])
        #expect(flow.depth == 1)

        flow.showNext(after: SampleData.todos[0])

        #expect(flow.depth == 0)                  // stack cleared with the root
        #expect(flow.topDestination == .detail)
    }

    @Test("the tag picker returns its selection through awaiting:")
    func tagPickerReturns() async {
        let store = TodoStore()
        let flow = makeFlow(store: store)
        let todo = SampleData.todos[0]

        flow.pickTags(for: todo)
        await waitUntil { flow.isPresentingModal }

        let picker = flow.descendant(ofType: TagPickerCoordinator.self)
        picker?.toggle("quick")                   // add
        picker?.toggle("urgent")                  // remove the existing one
        picker?.confirm()

        await waitUntil { store.todo(id: todo.id)?.tags == ["quick"] }
        #expect(!flow.isPresentingModal)
    }

    @Test("cancelling the picker leaves the tags untouched")
    func tagPickerCancelled() async {
        let store = TodoStore()
        let flow = makeFlow(store: store)
        let todo = SampleData.todos[0]

        flow.pickTags(for: todo)
        await waitUntil { flow.isPresentingModal }
        flow.descendant(ofType: TagPickerCoordinator.self)?.cancel()

        await waitUntil { !flow.isPresentingModal }
        #expect(store.todo(id: todo.id)?.tags == todo.tags)
    }

    @Test("the picker coordinator opts out of environment injection")
    func injectionOptOut() {
        let picker = TagPickerCoordinator(selected: [], tags: SampleData.tags)

        #expect(!picker._injectsCoordinator)
    }
}
