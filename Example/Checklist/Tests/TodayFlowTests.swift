import Testing
import Scaffolding
import ScaffoldingTesting
@testable import Checklist

/// The push/pop workhorse: policies, child-coordinator pushes, every pop
/// variant, and the seeded initializer. Modals live in TodayModalTests.
@MainActor
@Suite("Today flow")
struct TodayFlowTests {
    private func makeFlow(store: TodoStore = TodoStore()) -> TodayCoordinator {
        TodayCoordinator(store: store).activated()
    }

    @Test("a fresh flow sits at its root")
    func startsAtRoot() {
        let flow = makeFlow()

        #expect(flow.depth == 0)
        #expect(flow.topDestination == .today)
        #expect(!flow.isPresentingModal)
    }

    @Test("opening a task pushes a whole child coordinator")
    func childCoordinatorPush() {
        let flow = makeFlow()

        // expecting: hands the pushed child over as the route lands.
        let detail = flow.route(
            to: .todo(todo: SampleData.todos[0]),
            expecting: TodoDetailCoordinator.self
        )

        #expect(flow.hierarchyContains(TodayCoordinator.self, .todo, as: .push))
        #expect(detail?.topDestination == .detail)
    }

    @Test(".distinct guards the double tap; .always chains on purpose")
    func policies() {
        let flow = makeFlow()
        let todo = SampleData.todos[0]

        flow.open(todo)
        flow.open(todo)
        #expect(flow.count(of: .todo) == 1)

        flow.openAnother(SampleData.todos[1])
        #expect(flow.count(of: .todo) == 2)
        #expect(flow.depth == 2)
    }

    @Test("every pop variant behaves as documented")
    func popVariants() {
        let flow = makeFlow()
        for todo in SampleData.todos.prefix(4) { flow.openAnother(todo) }
        #expect(flow.depth == 4)

        flow.pop()
        #expect(flow.depth == 3)
        flow.pop(2)
        #expect(flow.depth == 1)
        flow.popToRoot()
        #expect(flow.depth == 0)
        #expect(flow.topDestination == .today)
    }

    @Test("the seeded initializer starts the flow one screen deep")
    func seededStart() {
        let flow = TodayCoordinator(store: TodoStore(), startingAt: SampleData.todos[1])

        #expect(flow.activated().depth == 1)
        #expect(flow.topDestination == .todo)
    }
}
