import SwiftUI
import Observation
import Scaffolding

@MainActor @Observable @Scaffoldable final class Probe: FlowCoordinatable { var stack = FlowStack<Probe>(root: .home(instance: 1)); func home(instance: Int) -> some View { EmptyView() } }
