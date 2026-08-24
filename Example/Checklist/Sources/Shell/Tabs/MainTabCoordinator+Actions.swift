import SwiftUI
import Scaffolding

// MARK: - Cross-tab actions

extension MainTabCoordinator {
    /// Zero-based position of the selected tab — handy for chrome and for
    /// asserting that a vetoed selection never moved.
    var selectedIndex: Int {
        tabItems.tabs.firstIndex { $0.id == tabItems.selectedTab } ?? 0
    }

    /// The overdue count rides on the Today tab. The `Int` overload clears
    /// the badge at zero, matching SwiftUI's `badge(_:)`.
    func refreshBadge() {
        setBadge(store.overdueCount, for: .today)
    }

    /// Deep-link leg: show one of the user's lists in the Lists tab.
    func openList(_ list: TodoList) {
        selectFirstTab(.lists) { (lists: ListsCoordinator) in
            lists.showTasks(in: .list(list))
        }
    }

    /// Deep-link leg: land straight on a task's detail.
    func openTodo(_ todo: Todo) {
        selectFirstTab(.today) { (today: TodayCoordinator) in
            today.popToRoot()
            today.open(todo)
        }
    }

    /// ⌘N on macOS (harmless on iPhone): compose in whichever tab is up.
    func addTodo() {
        selectFirstTab(.today) { (today: TodayCoordinator) in today.addTodo() }
    }

    /// Settings toggle → dynamic tab. Duplicates are allowed by the API,
    /// so guard with `isInTabItems`.
    func setStatsTab(enabled: Bool) {
        if enabled, !isInTabItems(.stats) {
            appendTab(.stats)
            setTabAccessibilityIdentifier("tab.stats", for: .stats)
        } else if !enabled {
            removeFirstTab(.stats)
        }
    }
}
