import SwiftUI
import Scaffolding

// A modal that contains navigation IS a coordinator concern: this picker
// pushes its own screens inside the sheet without touching the presenter's
// stack, because the coordinator boundary brings a fresh NavigationStack.
@Scaffoldable @Observable
final class PlanetPickerCoordinator: @MainActor FlowCoordinatable {
    var stack = FlowStack<PlanetPickerCoordinator>(root: .list)

    func list() -> some View { PickerListScreen() }
    func custom() -> some View { CustomPlanetScreen() }

    func openCustom() {
        route(to: .custom)
    }
}
