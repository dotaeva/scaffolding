import Testing
import Scaffolding
import ScaffoldingTesting
@testable import Checklist

/// Column visibility, focus mode, and the modals the split shell hosts.
@MainActor
@Suite("Split controls")
struct SplitControlTests {
    private func makeShell(store: TodoStore = TodoStore()) -> MainSplitCoordinator {
        MainSplitCoordinator(store: store).activated()
    }

    @Test("focus mode drops the task column and brings it back")
    func focusMode() {
        let split = makeShell()
        split.select(list: SampleData.lists[1])

        split.toggleFocusMode()
        #expect(split.isFocusMode)
        #expect(!split.anySplitColumns.hasContentColumn)

        split.toggleFocusMode()
        #expect(split.contentDestination == .tasks)
    }

    @Test("visibility and the compact column are coordinator state")
    func visibility() {
        let split = makeShell()

        split.setColumnVisibility(.detailOnly)
        #expect(!split.isSidebarVisible)
        split.toggleSidebar()
        #expect(split.isSidebarVisible)

        split.setPreferredCompactColumn(.detail)
        #expect(split.anySplitColumns.preferredCompactColumn == .detail)
    }

    @Test("settings presents as a sheet here, deduplicated")
    func settingsSheet() {
        let split = makeShell()

        split.showSettings()
        split.showSettings()

        #expect(split.anySplitColumns.modals.count == 1)
        // The same flow is a tab root on iPhone; here it knows it is modal.
        #expect(split.descendant(ofType: SettingsCoordinator.self)?.routeType == .sheet)
    }

    @Test("addTodo awaits the sub-flow, stores the task and selects it")
    func addTodo() async {
        let store = TodoStore()
        let split = makeShell(store: store)

        split.addTodo()
        await waitUntil { split.isPresentingModal }

        let compose = split.descendant(ofType: NewTodoCoordinator.self)
        compose?.draft.title = "File taxes"
        compose?.save()

        await waitUntil { split.selectedTodoID != nil }
        #expect(store.todos.contains { $0.title == "File taxes" })
        #expect(split.detailDestination == .detail)
    }
}
