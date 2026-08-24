import Testing
import Scaffolding
import ScaffoldingTesting
@testable import Checklist

/// Covers and awaited sub-flows presented from the Today tab.
@MainActor
@Suite("Today modals")
struct TodayModalTests {
    private func makeFlow(store: TodoStore = TodoStore()) -> TodayCoordinator {
        TodayCoordinator(store: store).activated()
    }

    @Test("the focus session is a cover, guarded against stacking")
    func focusCover() {
        let flow = makeFlow()

        flow.startFocusSession()
        flow.startFocusSession()

        #expect(flow.isPresentingModal)
        #expect(flow.count(of: .focus) == 1)
        flow.dismissModal()
        #expect(!flow.isPresentingModal)
    }

    @Test("addTodo awaits the sub-flow's returned task and pushes it")
    func addTodoReturnsValue() async {
        let store = TodoStore()
        let flow = makeFlow(store: store)
        let before = store.todos.count

        flow.addTodo()
        await waitUntil { flow.isPresentingModal }

        // descendant(ofType:) — the only way to a child the code under
        // test presented itself.
        let compose = flow.descendant(ofType: NewTodoCoordinator.self)
        compose?.draft.title = "Buy milk"
        compose?.save()

        await waitUntil { store.todos.count == before + 1 }
        #expect(!flow.isPresentingModal)
        #expect(flow.topDestination == .todo)
    }

    @Test("cancelling the sub-flow resumes the presenter with nil")
    func addTodoCancelled() async {
        let store = TodoStore()
        let flow = makeFlow(store: store)
        let before = store.todos.count

        flow.addTodo()
        await waitUntil { flow.isPresentingModal }
        flow.descendant(ofType: NewTodoCoordinator.self)?.cancel()

        await waitUntil { !flow.isPresentingModal }
        #expect(store.todos.count == before)
        #expect(flow.depth == 0)
    }
}
