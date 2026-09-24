import SwiftUI
import Scaffolding

// MARK: - Factory

extension UnauthenticatedCoordinator {
    func makeLogin() -> some View { LoginScreen() }

    func makeForgotPassword() -> some View { ForgotPasswordScreen() }

    func makeRegistration() -> any Coordinatable {
        RegistrationCoordinator(services: services)
    }
}
