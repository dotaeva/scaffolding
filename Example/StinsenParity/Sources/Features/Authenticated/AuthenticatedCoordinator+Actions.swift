import SwiftUI
import Scaffolding

// MARK: - Tab actions

extension AuthenticatedCoordinator {
    /// Zero-based position of the selected tab — handy for chrome, and for
    /// asserting in tests that a vetoed selection never moved.
    var selectedIndex: Int {
        tabItems.tabs.firstIndex { $0.id == tabItems.selectedTab } ?? 0
    }

    /// How many tabs currently resolve to this case. `isInTabItems(_:)`
    /// only answers yes/no, and a *second* copy of a tab is exactly what
    /// `appendTab` produces.
    func tabCount(of meta: Destinations.Meta) -> Int {
        tabItems.tabs.count { ($0.meta as? Destinations.Meta) == meta }
    }

    /// The selected tab as its generated `Meta` case.
    var selectedTab: Destinations.Meta? {
        tabItems.tabs
            .first { $0.id == tabItems.selectedTab }
            .flatMap { $0.meta as? Destinations.Meta }
    }

    /// Pops one tab's flow back to its root.
    ///
    /// Each tab hosts a different coordinator type, so the typed
    /// trailing-closure overload is used once per case — that closure
    /// only fires if the resolved child casts to the named type, which is
    /// what keeps this honest.
    func popTabToRoot(_ tab: Destinations.Meta) {
        switch tab {
        case .home:
            selectFirstTab(.home) { (home: HomeCoordinator) in home.popToRoot() }
        case .todos:
            selectFirstTab(.todos) { (todos: TodosCoordinator) in todos.popToRoot() }
        case .profile:
            selectFirstTab(.profile) { (profile: ProfileCoordinator) in profile.popToRoot() }
        case .testbed:
            selectFirstTab(.testbed) { (testbed: TestbedCoordinator) in testbed.popToRoot() }
        }
    }
}

// MARK: - AuthenticatedShell

extension AuthenticatedCoordinator: AuthenticatedShell {
    var location: String { "tab \(selectedIndex + 1) of \(tabItems.tabs.count)" }

    /// Switch to the Todos tab, clear whatever it had pushed, and open one
    /// task — the chain a deep link or a Home shortcut needs.
    ///
    /// Every step is one typed hop; no child coordinator is stored
    /// anywhere to make this reachable.
    func openTodo(id: UUID) {
        selectFirstTab(.todos) { (todos: TodosCoordinator) in
            todos.popToRoot()
            todos.open(id: id)
        }
    }

    /// The deep-link entry point: resolve the name against the store the
    /// shell already owns, then reuse the same chain.
    func openTodo(named name: String) {
        guard let todo = store.todo(named: name) else {
            toasts.showWarning("No task called “\(name)”")
            return
        }
        openTodo(id: todo.id)
        toasts.show("Opened “\(todo.name)”", symbol: "link")
    }
}
