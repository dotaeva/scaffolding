import SwiftUI
import Scaffolding

// A plain two-step flow. Route parameters become the enum case's payload,
// so `password(username:)` carries the address entered on step one.
@Scaffoldable @Observable
final class LoginCoordinator: @MainActor FlowCoordinatable {
    var stack = FlowStack<LoginCoordinator>(root: .email)

    func email() -> some View { EmailScreen() }
    func password(username: String) -> some View { PasswordScreen(username: username) }

    func continueWith(username: String) {
        route(to: .password(username: username))
    }
}
