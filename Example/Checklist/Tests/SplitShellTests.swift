import Testing
import Scaffolding
import ScaffoldingTesting
@testable import Checklist

/// The iPad/Mac shell's columns: what each one holds, how selection
/// replaces them, and pushes that stay inside the detail column.
@MainActor
@Suite("Split shell")
struct SplitShellTests {
    private func makeShell(store: TodoStore = TodoStore()) -> MainSplitCoordinator {
        MainSplitCoordinator(store: store).activated()
    }

    @Test("three columns are installed from the start")
    func initialColumns() {
        let split = makeShell()

        #expect(split.sidebarDestination == .sidebar)
        #expect(split.contentDestination == .tasks)
        #expect(split.detailDestination == .noSelection)
        #expect(split.anySplitColumns.hasContentColumn)
    }

    @Test("sidebar selection replaces the content column; re-selection keeps it")
    func contentReplacement() {
        let split = makeShell()

        split.select(list: SampleData.lists[0])
        let first = split.anySplitColumns.content?.id
        #expect(split.selectedSource == .list(SampleData.lists[0]))

        split.select(list: SampleData.lists[0])   // same source — guarded
        #expect(split.anySplitColumns.content?.id == first)

        split.select(smartList: .flagged)         // different — replaced
        #expect(split.anySplitColumns.content?.id != first)
    }

    @Test("task selection installs a detail flow and clears with the source")
    func detailReplacement() {
        let split = makeShell()

        split.select(todo: SampleData.todos[0])
        #expect(split.hierarchyContains(MainSplitCoordinator.self, .detail, as: .column(.detail)))
        #expect(split.descendant(ofType: TodoDetailCoordinator.self) != nil)

        // A new sidebar selection resets the detail column.
        split.select(smartList: .all)
        #expect(split.detailDestination == .noSelection)
        #expect(split.selectedTodoID == nil)
    }

    @Test("a pushed screen inside the detail column stays in that flow")
    func pushInsideDetail() {
        let split = makeShell()
        split.select(todo: SampleData.todos[0])
        let detail = split.descendant(ofType: TodoDetailCoordinator.self)?.activated()

        detail?.editNotes(for: SampleData.todos[0])

        #expect(detail?.depth == 1)
        #expect(split.hierarchyContains(TodoDetailCoordinator.self, .notes, as: .push))
    }
}
