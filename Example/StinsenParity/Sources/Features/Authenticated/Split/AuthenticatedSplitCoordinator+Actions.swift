import SwiftUI
import Scaffolding

// MARK: - Selection

extension AuthenticatedSplitCoordinator {
    /// Sidebar taps land here.
    ///
    /// The re-selection guard is on domain state rather than
    /// `RoutePolicy.distinct`, because it has to cover the *content*
    /// column too — a policy only ever guards the one destination being
    /// set, and re-selecting a section would still tear its column down
    /// and rebuild the flow inside it.
    func select(_ section: ShellSection) {
        guard section != self.section else { return }
        show(section, task: nil)
    }

    /// Middle-column taps replace the detail column.
    ///
    /// Guarded on the id, **not** `.distinct`: every task resolves to the
    /// same `.todo` case, and `.distinct` compares cases only — it would
    /// swallow a switch from one task to another.
    func open(id: UUID) {
        guard id != selectedTodoID else { return }
        selectedTodoID = id
        setDetail(.todo(id: id))
    }

    /// The one place columns are assigned. It takes the task to land on
    /// so a deep link arriving while another section is showing builds the
    /// detail column once, instead of flashing a placeholder first.
    func show(_ section: ShellSection, task: UUID?) {
        self.section = section
        selectedTodoID = task

        switch section {
        case .todos:
            // Installs the middle column: the container swaps to
            // NavigationSplitView's three-column form.
            setContent(.todos)
            setDetail(task.map { .todo(id: $0) } ?? .noSelection)
        case .home:
            removeContent()
            setDetail(.home)
        case .profile:
            removeContent()
            setDetail(.profile)
        case .testbed:
            removeContent()
            setDetail(.testbed)
        }
    }

    /// Same intent as `TodosCoordinator.toggleFavorite`. Each shell is the
    /// composition root of its own tree and owns its own intents; neither
    /// hosts the other's coordinator to borrow one from.
    func toggleFavorite(_ id: UUID) {
        store.toggleFavorite(id)
        guard let todo = store[id] else { return }
        if todo.isFavorite {
            toasts.show("“\(todo.name)” added to Home", symbol: "star.fill", tint: .yellow)
        } else {
            toasts.showNeutral("“\(todo.name)” removed from Home", symbol: "star.slash")
        }
    }
}
