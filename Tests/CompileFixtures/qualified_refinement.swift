import SwiftUI
import Observation
import Scaffolding

protocol CustomFlow: FlowCoordinatable {}
@MainActor @Observable @Scaffoldable
final class RefinedCoordinator: CustomFlow {
    var stack = Scaffolding.FlowStack<RefinedCoordinator>(root: .home)
    func home() -> some SwiftUI.View { EmptyView() }
}
