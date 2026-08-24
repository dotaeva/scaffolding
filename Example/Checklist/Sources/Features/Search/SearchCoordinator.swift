import SwiftUI
import Scaffolding

/// The Search tab. Its tab route returns the three-element tuple, so the
/// system renders it with `TabRole.search`.
@MainActor
@Observable
@Scaffoldable(codable: true)
final class SearchCoordinator: @MainActor FlowCoordinatable {
    var stack = FlowStack<SearchCoordinator>(root: .search)

    let store: TodoStore

    init(store: TodoStore) {
        self.store = store
    }

    // MARK: Routes

    func search() -> some View {
        SearchView(viewModel: SearchViewModel(store: store))
    }

    func todo(todo: Todo) -> any Coordinatable {
        TodoDetailCoordinator(todo: todo, store: store)
    }
}

// MARK: - Navigation

extension SearchCoordinator {
    func open(_ todo: Todo) {
        route(to: .todo(todo: todo), policy: .distinct)
    }
}

// MARK: - Chrome

extension SearchCoordinator {
    /// Declared in an extension, so the macro never sees it — no
    /// `@ScaffoldingIgnored` needed here, unlike the same method in
    /// `OnboardingCoordinator`'s class body.
    func customize(_ view: AnyView) -> some View {
        view.scrollDismissesKeyboard(.immediately)
    }
}
