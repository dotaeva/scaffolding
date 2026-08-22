import SwiftUI
import Scaffolding

@MainActor
@Observable
@Scaffoldable(codable: true)
final class LoginCoordinator: @MainActor FlowCoordinatable {
    var stack = FlowStack<LoginCoordinator>(root: .email)

    // MARK: Routes — parameters become enum-case payloads.
    // Routes must be declared in the class body — @Scaffoldable scans only
    // the class declaration, never extensions.

    func email() -> some View { EmailScreen() }
    func password(username: String) -> some View { PasswordScreen(username: username) }
}

// MARK: - Actions

extension LoginCoordinator {
    func continueWith(username: String) {
        route(to: .password(username: username))
    }

    func submit() {
        // The auth swap belongs to the app root. Coordinators reach up with
        // ancestor(ofType:); views would read AppCoordinator from @Environment.
        ancestor(ofType: AppCoordinator.self)?.signIn()
    }
}
