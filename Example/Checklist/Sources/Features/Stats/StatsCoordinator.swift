import SwiftUI
import Scaffolding

/// The dynamic Stats tab, added and removed at runtime from Settings and
/// gated by the tab shell's `shouldSelect`.
@MainActor
@Observable
@Scaffoldable(codable: true)
final class StatsCoordinator: @MainActor FlowCoordinatable {
    var stack = FlowStack<StatsCoordinator>(root: .stats)

    let store: TodoStore

    init(store: TodoStore) {
        self.store = store
    }

    // MARK: Routes

    func stats() -> some View {
        StatsView(viewModel: StatsViewModel(store: store))
    }

    func listBreakdown(list: TodoList) -> some View {
        ListBreakdownView(list: list, viewModel: StatsViewModel(store: store))
    }
}

// MARK: - Navigation

extension StatsCoordinator {
    func open(_ list: TodoList) {
        route(to: .listBreakdown(list: list), policy: .distinct)
    }
}
