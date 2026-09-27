import SwiftUI
import Observation
import Scaffolding

@MainActor @Observable @Scaffoldable(injectsCoordinator: false)
package final class FeatureCoordinator: FlowCoordinatable {
    package var stack = FlowStack<FeatureCoordinator>(root: .home)
    package init() {}
    func home() -> some View { EmptyView() }
}
