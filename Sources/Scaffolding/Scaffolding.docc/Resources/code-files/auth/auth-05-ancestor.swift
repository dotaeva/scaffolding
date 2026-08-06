import SwiftUI
import Scaffolding

@Scaffoldable @Observable
final class LoginCoordinator: @MainActor FlowCoordinatable {
    var stack = FlowStack<LoginCoordinator>(root: .email)

    func email() -> some View { EmailScreen() }
    func password(username: String) -> some View { PasswordScreen(username: username) }

    func continueWith(username: String) {
        route(to: .password(username: username))
    }

    func submit() {
        // The swap belongs to the app root, not to this flow. Coordinators
        // reach up with ancestor(ofType:) — no stored parent references.
        ancestor(ofType: AppRootCoordinator.self)?.signIn()
    }
}
