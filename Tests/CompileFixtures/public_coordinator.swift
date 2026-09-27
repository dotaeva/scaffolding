import SwiftUI
import Observation
import Scaffolding

@MainActor @Observable @Scaffoldable public final class Probe: FlowCoordinatable { public var stack = FlowStack<Probe>(root: .home); public init() {}; func home() -> some View { EmptyView() } }
