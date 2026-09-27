import SwiftUI
import Observation
import Scaffolding

@MainActor @Observable @Scaffoldable(injectsCoordinator: 1 == 2) final class Probe: FlowCoordinatable { var stack = FlowStack<Probe>(root: .home); func home() -> some View { EmptyView() } }
