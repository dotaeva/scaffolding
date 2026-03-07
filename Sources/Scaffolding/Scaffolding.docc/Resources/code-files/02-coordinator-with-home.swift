import SwiftUI
import Scaffolding

@Scaffoldable @Observable
final class AppCoordinator: @MainActor FlowCoordinatable {
    var stack = FlowStack<AppCoordinator>(root: .home)

    func home() -> some View {
        Text("Home")
    }
}
