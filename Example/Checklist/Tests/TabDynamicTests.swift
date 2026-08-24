import Testing
import Scaffolding
import ScaffoldingTesting
@testable import Checklist

/// Runtime tab mutation, badges, and accessibility identifiers.
@MainActor
@Suite("Tab dynamics")
struct TabDynamicTests {
    private func makeShell(store: TodoStore = TodoStore()) -> MainTabCoordinator {
        MainTabCoordinator(store: store).activated()
    }

    @Test("the Stats tab is appended and removed dynamically")
    func dynamicTab() {
        let tabs = makeShell()
        #expect(!tabs.isInTabItems(.stats))

        tabs.setStatsTab(enabled: true)
        tabs.setStatsTab(enabled: true)          // guarded — no duplicate
        #expect(tabs.tabItems.tabs.count == 5)

        tabs.setStatsTab(enabled: false)
        #expect(!tabs.isInTabItems(.stats))
    }

    @Test("insert, last-selection and setTabs round out the dynamic API")
    func dynamicTabAPI() {
        let tabs = makeShell()
        tabs.insertTab(.stats, at: 1)
        tabs.appendTab(.stats)
        tabs.selectLastTab(.stats)
        #expect(tabs.hierarchyContains(MainTabCoordinator.self, .stats, as: .tab(index: 5, isSelected: true)))

        tabs.removeLastTab(.stats)
        tabs.setTabs([.today, .lists, .search, .settings])
        #expect(tabs.tabItems.tabs.count == 4)
        #expect(!tabs.isInTabItems(.stats))
    }

    @Test("the badge tracks overdue tasks and clears at zero")
    func badge() {
        let store = TodoStore()
        let tabs = makeShell(store: store)
        #expect(tabs.badge(for: .today) == "\(store.overdueCount)")
        #expect(tabs.tabAccessibilityIdentifier(for: .today) == "tab.today")

        for todo in store.todos where todo.isOverdue { store.toggleDone(todo) }
        tabs.refreshBadge()
        #expect(tabs.badge(for: .today) == nil)
    }
}
