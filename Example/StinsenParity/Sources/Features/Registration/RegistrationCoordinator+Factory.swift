import SwiftUI
import Scaffolding

// MARK: - Factory

extension RegistrationCoordinator {
    func makeUsername() -> some View { UserRegistrationScreen() }

    func makePassword(username: String) -> some View {
        PasswordRegistrationScreen(username: username)
    }
}
