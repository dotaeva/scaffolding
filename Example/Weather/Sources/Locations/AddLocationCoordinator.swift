import SwiftUI
import Scaffolding

/// Modal sub-flow whose whole job is returning a value: search → confirm,
/// then dismissCoordinator(returning:) hands the picked city back to the
/// awaiting presenter. Cancelling (or swiping down) resumes it with nil.
///
/// Not `codable:` — whole-tree restoration records this modal without its
/// internal state and simply doesn't re-present it.
@MainActor
@Observable
@Scaffoldable
final class AddLocationCoordinator: @MainActor FlowCoordinatable {
    var stack = FlowStack<AddLocationCoordinator>(root: .search)

    // MARK: Routes

    func search() -> some View { CitySearchScreen() }
    func confirm(city: Location) -> some View { CityConfirmScreen(city: city) }
}

// MARK: - Steps

extension AddLocationCoordinator {
    func select(_ city: Location) {
        route(to: .confirm(city: city), policy: .distinct)
    }

    /// Deliver the result and dismiss the whole sub-flow — not pop():
    /// dismissCoordinator removes the coordinator from its presenter.
    func finish(with city: Location) {
        dismissCoordinator(returning: city)
    }

    /// Plain dismissCoordinator() — the presenter's `awaiting:` call
    /// resumes with nil, so cancellation needs no separate channel.
    func cancel() {
        dismissCoordinator()
    }
}
