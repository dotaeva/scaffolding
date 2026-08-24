import Testing
import Scaffolding
import ScaffoldingTesting
@testable import Checklist

/// Whole-tree capture and replay for both shells.
@MainActor
@Suite("State restoration")
struct RestorationTests {

    @Test("a deep tab tree round-trips: root, selection and pushes")
    func tabTreeRoundTrips() throws {
        let app = AppCoordinator(layout: .tabs).activated()
        app.finishOnboarding()
        let tabs = app.descendant(ofType: MainTabCoordinator.self)
        let lists = tabs?.selectFirstTab(.lists, expecting: ListsCoordinator.self)?.activated()
        lists?.showTasks(in: .list(SampleData.lists[1]))
        lists?.open(SampleData.todos[4])
        tabs?.selectFirstTab(.search)

        let data = try app.captureNavigationState()

        let restored = AppCoordinator(layout: .tabs).activated()
        try restored.restoreNavigationState(from: data)

        #expect(restored.isRoot(.main))
        #expect(restored.hierarchyContains(MainTabCoordinator.self, .search, as: .tab(index: 2, isSelected: true)))
        #expect(restored.hierarchyContains(ListsCoordinator.self, .tasks, as: .push))
        #expect(restored.hierarchyContains(ListsCoordinator.self, .todo, as: .push))
    }

    @Test("the split tree round-trips both of its columns")
    func splitTreeRoundTrips() throws {
        let app = AppCoordinator(layout: .split).activated()
        app.finishOnboarding()
        let split = app.descendant(ofType: MainSplitCoordinator.self)
        split?.select(list: SampleData.lists[2])
        split?.select(todo: SampleData.todos[9])

        let data = try app.captureNavigationState()

        let restored = AppCoordinator(layout: .split).activated()
        try restored.restoreNavigationState(from: data)

        #expect(restored.hierarchyContains(MainSplitCoordinator.self, .tasks, as: .column(.content)))
        #expect(restored.hierarchyContains(MainSplitCoordinator.self, .detail, as: .column(.detail)))
        #expect(restored.descendant(ofType: TodoDetailCoordinator.self)?.topDestination == .detail)
    }

    @Test("a pushed screen inside a restored detail column survives")
    func nestedPushRoundTrips() throws {
        let app = AppCoordinator(layout: .split).activated()
        app.finishOnboarding()
        let split = app.descendant(ofType: MainSplitCoordinator.self)
        split?.select(todo: SampleData.todos[0])
        split?.descendant(ofType: TodoDetailCoordinator.self)?
            .activated()
            .editNotes(for: SampleData.todos[0])

        let data = try app.captureNavigationState()

        let restored = AppCoordinator(layout: .split).activated()
        try restored.restoreNavigationState(from: data)

        #expect(restored.hierarchyContains(TodoDetailCoordinator.self, .notes, as: .push))
    }
}
