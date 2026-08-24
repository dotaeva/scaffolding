import Testing
import Scaffolding
import ScaffoldingTesting
@testable import Checklist

/// Three levels on one stack, and the search screen's filtering.
@MainActor
@Suite("Lists and search")
struct ListsAndSearchTests {

    @Test("lists → tasks → task builds a three-deep stack")
    func threeLevels() {
        let lists = ListsCoordinator(store: TodoStore()).activated()

        lists.showTasks(in: .list(SampleData.lists[0]))
        lists.open(SampleData.todos[0])

        #expect(lists.depth == 2)
        #expect(lists.topDestination == .todo)
        #expect(lists.isInStack(.tasks))
    }

    @Test("popToFirst and popToLast walk back to a case")
    func popToCase() {
        let lists = ListsCoordinator(store: TodoStore()).activated()
        // Note the interleaving: two `.tasks` pushes in a row would be
        // swallowed by the .distinct policy, since it compares cases.
        lists.showTasks(in: .list(SampleData.lists[0]))
        lists.open(SampleData.todos[0])
        lists.showTasks(in: .list(SampleData.lists[1]))
        lists.open(SampleData.todos[4])
        #expect(lists.depth == 4)

        lists.popToLast(.tasks)
        #expect(lists.depth == 3)
        lists.popToFirst(.tasks)
        #expect(lists.depth == 1)
    }

    @Test("the deep-link target rebuilds the stack under the task")
    func deepLinkTarget() {
        let lists = ListsCoordinator(store: TodoStore()).activated()
        lists.showTasks(in: .smart(.all))
        lists.open(SampleData.todos[3])

        lists.showTodo(SampleData.todos[5])   // a Home task

        // popToRoot + list + task — not five screens deep.
        #expect(lists.depth == 2)
        #expect(lists.topDestination == .todo)
    }

    @Test("the task list view model reflects its source")
    func taskListSources() {
        let store = TodoStore()
        let work = TaskListViewModel(source: .list(SampleData.lists[0]), store: store)
        let flagged = TaskListViewModel(source: .smart(.flagged), store: store)

        let allWork = work.todos.allSatisfy { $0.listID == "work" }
        let allFlagged = flagged.todos.allSatisfy(\.isFlagged)
        #expect(allWork)
        #expect(allFlagged)
        // Inside one list the row hides the list name; smart lists show it.
        #expect(work.listName(for: work.todos[0]) == nil)
        #expect(flagged.listName(for: flagged.todos[0]) != nil)
    }

    @Test("search filters by text and scope")
    func searchFiltering() {
        let store = TodoStore()
        let viewModel = SearchViewModel(store: store)

        viewModel.query = "passport"
        #expect(viewModel.results.count == 1)

        viewModel.query = ""
        viewModel.scope = .done
        let onlyDone = viewModel.results.allSatisfy(\.isDone)
        #expect(onlyDone)

        viewModel.scope = .flagged
        let onlyFlagged = viewModel.results.allSatisfy(\.isFlagged)
        #expect(onlyFlagged)

        // Tags are searchable too.
        viewModel.scope = .all
        viewModel.query = "errand"
        #expect(viewModel.results.count == 1)
    }

    @Test("opening a result pushes the shared detail coordinator")
    func searchPush() {
        let search = SearchCoordinator(store: TodoStore()).activated()

        search.open(SampleData.todos[2])

        #expect(search.hierarchyContains(SearchCoordinator.self, .todo, as: .push))
        #expect(search.descendant(ofType: TodoDetailCoordinator.self) != nil)
    }
}
