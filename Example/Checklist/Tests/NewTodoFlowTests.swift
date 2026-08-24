import Testing
import Scaffolding
import ScaffoldingTesting
@testable import Checklist

/// The value-returning modal sub-flow, including `routeAndWait` inside it.
@MainActor
@Suite("New task flow")
struct NewTodoFlowTests {
    private func makeFlow(store: TodoStore = TodoStore()) -> NewTodoCoordinator {
        NewTodoCoordinator(source: .list(SampleData.lists[0]), store: store).activated()
    }

    @Test("the draft starts in the source list")
    func draftDefaults() {
        let flow = makeFlow()

        #expect(flow.draft.listID == "work")
        #expect(!flow.draft.canSave)   // no title yet
    }

    @Test("chooseList suspends in routeAndWait until the picker pops")
    func routeAndWaitResumes() async {
        let flow = makeFlow()

        flow.chooseList()
        await waitUntil { flow.topDestination == .listPicker }

        flow.draft.select(list: SampleData.lists[2])   // what the picker does
        flow.pop()

        await waitUntil { flow.draft.lastPickedListName != nil }
        #expect(flow.draft.listID == "reading")
        #expect(flow.depth == 0)
    }

    @Test("build produces a task with a fresh id and the draft's fields")
    func buildsTask() {
        let store = TodoStore()
        let flow = makeFlow(store: store)
        flow.draft.title = "  Water the plants  "
        flow.draft.priority = .high
        flow.draft.hasDueDate = true
        flow.draft.toggle(tag: "quick")

        let built = flow.draft.build()

        #expect(built?.title == "Water the plants")   // trimmed
        #expect(built?.priority == .high)
        #expect(built?.dueDate != nil)
        #expect(built?.tags == ["quick"])
        #expect(built?.id == (store.todos.map(\.id).max() ?? 0) + 1)
        // build() does not insert: the presenter does that when the
        // awaiting: call resumes.
        #expect(store.todo(id: built?.id ?? -1) == nil)
    }

    @Test("an empty title cannot be saved")
    func emptyTitleGuard() {
        let flow = makeFlow()
        flow.draft.title = "   "

        #expect(!flow.draft.canSave)
        #expect(flow.draft.build() == nil)
    }
}
