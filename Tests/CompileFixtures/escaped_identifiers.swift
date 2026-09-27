import SwiftUI
import Observation
import Scaffolding

@MainActor @Observable @Scaffoldable
final class EscapedCoordinator: FlowCoordinatable {
    var stack = FlowStack<EscapedCoordinator>(root: .default(class: 1))
    func `default`(`class`: Int) -> some View { Text("Value") }
}
