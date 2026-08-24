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
    // The route table: one line per destination, with the bodies in
    // SearchCoordinator+Factory.swift. These declarations have to stay in the class
    // body — @Scaffoldable scans only the class declaration, so a route
    // moved to an extension is silently untracked.

    func search() -> some View { makeSearch() }

    func todo(todo: Todo) -> any Coordinatable { makeTodo(todo: todo) }
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
