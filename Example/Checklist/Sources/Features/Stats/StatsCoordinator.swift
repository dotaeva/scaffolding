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
    // The route table: one line per destination, with the bodies in
    // StatsCoordinator+Factory.swift. These declarations have to stay in the class
    // body — @Scaffoldable scans only the class declaration, so a route
    // moved to an extension is silently untracked.

    func stats() -> some View { makeStats() }

    func listBreakdown(list: TodoList) -> some View { makeListBreakdown(list: list) }
}

// MARK: - Navigation

extension StatsCoordinator {
    func open(_ list: TodoList) {
        route(to: .listBreakdown(list: list), policy: .distinct)
    }
}
