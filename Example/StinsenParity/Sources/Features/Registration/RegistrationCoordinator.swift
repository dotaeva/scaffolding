import SwiftUI
import Scaffolding

/// A two-step sub-flow presented as a sheet: pick a username, then a
/// password. It exists to show a *presented coordinator that returns a
/// value* — the presenter awaits it and never inspects its state.
@MainActor
@Observable
@Scaffoldable
final class RegistrationCoordinator: @MainActor FlowCoordinatable {
    var stack = FlowStack<RegistrationCoordinator>(root: .username)

    let services: UnauthenticatedServices

    var isWorking = false

    init(services: UnauthenticatedServices) {
        self.services = services
    }

    // MARK: Routes

    func username() -> some View { makeUsername() }

    func password(username: String) -> some View { makePassword(username: username) }
}

// MARK: - Steps

extension RegistrationCoordinator {
    func chooseUsername(_ username: String) {
        route(to: .password(username: username), policy: .distinct)
    }

    /// Hands the new user back to whoever is awaiting this coordinator and
    /// closes it in one call.
    func register(username: String, password: String) {
        Task {
            isWorking = true
            defer { isWorking = false }
            guard let user = try? await services.register(username: username, password: password) else {
                return
            }
            dismissCoordinator(returning: user)
        }
    }

    /// Resumes the awaiting presenter with `nil`.
    func cancel() {
        dismissCoordinator()
    }
}

// MARK: - Presented content

extension RegistrationCoordinator {
    func customize(_ view: AnyView) -> some View {
        view.presentationDetents([.large])
    }
}
