import SwiftUI
import Scaffolding

@Scaffoldable @Observable
final class PlanetPickerCoordinator: @MainActor FlowCoordinatable {
    var stack = FlowStack<PlanetPickerCoordinator>(root: .list)

    func list() -> some View { PickerListScreen() }
    func custom() -> some View { CustomPlanetScreen() }

    func openCustom() {
        route(to: .custom)
    }

    /// Hands the value to the presenter's `awaiting:` call, then closes.
    func pick(_ planet: String) {
        dismissCoordinator(returning: planet)
    }

    /// A plain dismissal — the presenter resumes with nil.
    func cancel() {
        dismissCoordinator()
    }
}
