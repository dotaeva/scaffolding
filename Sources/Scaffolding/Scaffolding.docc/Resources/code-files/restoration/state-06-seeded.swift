import SwiftUI
import Scaffolding

@Scaffoldable(codable: true) @Observable
final class PlanetsCoordinator: @MainActor FlowCoordinatable {
    var stack: FlowStack<PlanetsCoordinator>

    // For a known start position you do not need capture/restore at all —
    // construct the flow already deep in its stack. The macro synthesises
    // no init(initialRoute:), so write the initializer yourself.
    init(startingAt planet: String? = nil) {
        stack = planet.map { FlowStack(root: .planets, pushing: [.detail(name: $0)]) }
            ?? FlowStack(root: .planets)
    }

    func planets() -> some View { PlanetsView() }
    func detail(name: String) -> some View { DetailView(name: name) }
}

// Handy for previews, too: render a mid-flow state without any routing.
#Preview("Detail pushed") {
    PlanetsCoordinator(startingAt: "Mars").view
}
