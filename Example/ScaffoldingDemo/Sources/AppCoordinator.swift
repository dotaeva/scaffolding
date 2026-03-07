import SwiftUI
import Scaffolding

@Scaffoldable @Observable
final class AppCoordinator: @MainActor FlowCoordinatable {
    var stack = FlowStack<AppCoordinator>(root: .home)

    func home() -> some View {
        HomeView()
    }

    func detail(title: String) -> some View {
        DetailView(title: title)
    }

    func settings() -> some View {
        SettingsView()
    }
}
