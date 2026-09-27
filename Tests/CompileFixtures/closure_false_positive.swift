import SwiftUI
import Observation
import Scaffolding

@MainActor @Observable @Scaffoldable final class Probe: FlowCoordinatable { var stack = FlowStack<Probe>(root: .home); func home() -> some View { EmptyView() }; func helper() -> () -> (any Coordinatable, TabRole) { fatalError() } }
