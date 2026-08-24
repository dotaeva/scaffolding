import Foundation
import Scaffolding

// MARK: - Deep links
// checklist://today · checklist://list/work · checklist://todo/6

extension AppCoordinator {
    func handle(_ url: URL) {
        // isRoot compares by Meta — never deep-link past onboarding.
        guard isRoot(.main) else { return }

        switch url.host() {
        case "today":
            openToday()
        case "list":
            guard let list = store.list(id: url.lastPathComponent) else { return }
            open(list)
        case "todo":
            guard let id = Int(url.lastPathComponent), let todo = store.todo(id: id) else { return }
            open(todo)
        default:
            break
        }
    }

    /// Typed trailing closures: each hop resolves its child and hands it
    /// over. `setRoot` re-runs the route function, so the main tree is
    /// rebuilt — the cold-launch pattern.
    private func openToday() {
        switch layout {
        case .tabs:
            setRoot(.main) { (tabs: MainTabCoordinator) in
                tabs.selectFirstTab(.today) { (today: TodayCoordinator) in today.popToRoot() }
            }
        case .split:
            setRoot(.main) { (split: MainSplitCoordinator) in split.select(smartList: .today) }
        }
    }

    private func open(_ list: TodoList) {
        switch layout {
        case .tabs:
            setRoot(.main) { (tabs: MainTabCoordinator) in tabs.openList(list) }
        case .split:
            setRoot(.main) { (split: MainSplitCoordinator) in split.select(list: list) }
        }
    }

    /// The same walk with the `expecting:` variants — flatter, and easy to
    /// branch mid-chain.
    private func open(_ todo: Todo) {
        switch layout {
        case .tabs:
            let tabs = setRoot(.main, expecting: MainTabCoordinator.self)
            tabs?.openTodo(todo)
        case .split:
            let split = setRoot(.main, expecting: MainSplitCoordinator.self)
            if let list = store.list(id: todo.listID) {
                split?.select(list: list)
            }
            split?.select(todo: todo)
        }
    }
}
