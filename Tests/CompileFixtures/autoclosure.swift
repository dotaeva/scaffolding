import SwiftUI
import Observation
import Scaffolding

@MainActor @Observable @Scaffoldable
final class Probe: FlowCoordinatable {
    var stack = FlowStack<Probe>(root: .home(value: { true }))
    func home(value: @autoclosure () -> Bool) -> some View {
        Text(String(value()))
    }
}
