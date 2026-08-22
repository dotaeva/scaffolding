import SwiftUI
import Scaffolding

@MainActor
@Observable
@Scaffoldable(codable: true)
final class ProfileCoordinator: @MainActor GlassTabFlow {
    var stack = FlowStack<ProfileCoordinator>(root: .profile)

    // MARK: Routes
    // Routes must be declared in the class body — @Scaffoldable scans only
    // the class declaration, never extensions.

    func profile() -> some View { ProfileScreen().tabScreenFade() }
    func developer() -> some View { DeveloperScreen() }
}

// MARK: - Navigation

extension ProfileCoordinator {
    func openDeveloper() {
        route(to: .developer)
    }
}
