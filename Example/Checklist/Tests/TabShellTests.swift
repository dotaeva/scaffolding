import Testing
import Scaffolding
import ScaffoldingTesting
@testable import Checklist

/// Tab selection and the `shouldSelect` interception hook.
@MainActor
@Suite("Tab shell")
struct TabShellTests {
    private func makeShell(store: TodoStore = TodoStore()) -> MainTabCoordinator {
        MainTabCoordinator(store: store).activated()
    }

    @Test("selection APIs move the selected tab")
    func selection() {
        let tabs = makeShell()
        #expect(tabs.hierarchyContains(MainTabCoordinator.self, .today, as: .tab(index: 0, isSelected: true)))

        tabs.selectFirstTab(.settings)
        #expect(tabs.hierarchyContains(MainTabCoordinator.self, .settings, as: .tab(index: 3, isSelected: true)))

        tabs.select(index: 2)
        #expect(tabs.hierarchyContains(MainTabCoordinator.self, .search, as: .tab(index: 2, isSelected: true)))

        if let first = tabs.tabItems.tabs.first?.id { tabs.select(id: first) }
        #expect(tabs.selectedIndex == 0)
    }

    @Test("re-tapping the selected tab pops its flow to the root")
    func reselectionPops() {
        let tabs = makeShell()
        let today = tabs.selectFirstTab(.today, expecting: TodayCoordinator.self)?.activated()
        today?.open(SampleData.todos[0])
        #expect(today?.depth == 1)

        _ = tabs.shouldSelect(tab: .today, isReselection: true)

        #expect(today?.depth == 0)
    }

    @Test("the Stats tab is vetoed until something is completed")
    func statsGate() {
        let store = TodoStore(todos: SampleData.todos.map { todo in
            var open = todo
            open.isDone = false
            return open
        })
        let tabs = makeShell(store: store)
        tabs.setStatsTab(enabled: true)

        #expect(!tabs.shouldSelect(tab: .stats, isReselection: false))
        #expect(tabs.isPresentingModal)          // the explainer sheet
        #expect(tabs.selectedIndex == 0)         // selection never moved

        tabs.dismissModal()
        store.toggleDone(store.todos[0])
        #expect(tabs.shouldSelect(tab: .stats, isReselection: false))
    }

    @Test("cross-tab actions select the tab and drive its flow")
    func crossTabActions() {
        let tabs = makeShell()

        tabs.openList(SampleData.lists[1])
        #expect(tabs.hierarchyContains(ListsCoordinator.self, .tasks, as: .push))

        tabs.openTodo(SampleData.todos[4])
        #expect(tabs.hierarchyContains(TodayCoordinator.self, .todo, as: .push))
        #expect(tabs.selectedIndex == 0)
    }
}
