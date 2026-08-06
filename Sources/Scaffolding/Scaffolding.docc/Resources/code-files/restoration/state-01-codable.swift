import SwiftUI
import Scaffolding

// codable: true makes the generated Destinations enum Codable, which is
// what capture and restore walk. Every participating coordinator opts in.
@Scaffoldable(codable: true) @Observable
final class PlanetsCoordinator: @MainActor FlowCoordinatable {
    var stack = FlowStack<PlanetsCoordinator>(root: .planets)

    func planets() -> some View { PlanetsView() }
    func detail(name: String) -> some View { DetailView(name: name) }
}
