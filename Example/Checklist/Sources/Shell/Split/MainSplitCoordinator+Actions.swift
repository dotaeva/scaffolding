import SwiftUI
import Scaffolding

// MARK: - Selection

extension MainSplitCoordinator {
    func select(list: TodoList) {
        select(source: .list(list))
    }

    func select(smartList: SmartList) {
        select(source: .smart(smartList))
    }

    /// Sidebar taps land here. The guard is on domain state because every
    /// source resolves to the same `.tasks` case.
    func select(source: TaskSource) {
        guard source != selectedSource || !anySplitColumns.hasContentColumn else { return }
        selectedSource = source
        selectedTodoID = nil
        setContent(.tasks(source: source))
        setDetail(.noSelection)
    }

    /// Middle-column taps replace the detail column with a fresh flow.
    func select(todo: Todo) {
        guard todo.id != selectedTodoID else { return }
        selectedTodoID = todo.id
        setDetail(.detail(todo: todo))
    }

    func clearDetail() {
        selectedTodoID = nil
        setDetail(.noSelection, policy: .distinct)
    }
}

// MARK: - Columns

extension MainSplitCoordinator {
    /// Focus mode drops the middle column entirely (the container swaps to
    /// `NavigationSplitView`'s two-column form) and brings it back.
    func toggleFocusMode() {
        if anySplitColumns.hasContentColumn {
            removeContent()
        } else {
            setContent(.tasks(source: selectedSource))
        }
    }

    var isFocusMode: Bool { !anySplitColumns.hasContentColumn }
}

// MARK: - Modals

extension MainSplitCoordinator {
    func showSettings() {
        present(.settings, as: .sheet, policy: .distinct)
    }

    /// `present(_:awaiting:)` suspends until the sub-flow is dismissed and
    /// returns whatever it passed to `dismissCoordinator(returning:)` —
    /// `nil` for a cancel or a swipe-down, so cancellation is free.
    func addTodo() {
        Task {
            let created = await present(
                .newTodo(source: selectedSource),
                as: .sheet(detents: [.large]),
                awaiting: Todo.self
            )
            guard let created else { return }
            store.add(created)
            select(todo: created)
        }
    }
}
