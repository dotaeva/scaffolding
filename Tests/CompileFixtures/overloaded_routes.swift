import SwiftUI
import Observation
import Scaffolding

@MainActor @Observable @Scaffoldable final class Probe: FlowCoordinatable { var stack = FlowStack<Probe>(root: .home(id: 1)); func home(id: Int) -> some View { EmptyView() }; func home(name: String) -> some View { EmptyView() } }
