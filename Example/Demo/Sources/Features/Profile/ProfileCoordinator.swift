import SwiftUI
import Scaffolding

@MainActor
@Observable
@Scaffoldable(codable: true)
final class ProfileCoordinator: @MainActor GlassTabFlow {
    var stack = FlowStack<ProfileCoordinator>(root: .profile)

    func profile() -> some View { ProfileScreen().tabScreenFade() }
    func developer() -> some View { DeveloperScreen() }

    func openDeveloper() {
        route(to: .developer)
    }
}
