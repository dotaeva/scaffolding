import SwiftUI
import Scaffolding

@Scaffoldable @Observable
final class AppCoordinator: @MainActor FlowCoordinatable {
    var stack = FlowStack<AppCoordinator>(root: .home)
}
