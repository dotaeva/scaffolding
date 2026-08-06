import SwiftUI
import Scaffolding

// Renamed from AppCoordinator — this flow now owns one tab, not the app.
@Scaffoldable @Observable
final class PlanetsCoordinator: @MainActor FlowCoordinatable {
    var stack = FlowStack<PlanetsCoordinator>(root: .planets)

    func planets() -> some View { PlanetsView() }
    func detail(name: String) -> some View { DetailView(name: name) }
}
