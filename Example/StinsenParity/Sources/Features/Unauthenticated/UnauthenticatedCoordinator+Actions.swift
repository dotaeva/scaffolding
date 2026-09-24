import SwiftUI
import Scaffolding

// MARK: - Actions
// Void return types are never macro-tracked — no attribute needed.

extension UnauthenticatedCoordinator {
    func signIn(username: String, password: String) {
        Task {
            isWorking = true
            defer { isWorking = false }
            do {
                let user = try await services.login(username: username, password: password)
                // The result belongs to the app root, so it goes up the
                // tree rather than sideways into another coordinator.
                ancestor(ofType: MainCoordinator.self)?.signIn(user)
            } catch {
                toasts.showWarning(error.localizedDescription)
            }
        }
    }

    func showForgotPassword() {
        route(to: .forgotPassword, policy: .distinct)
    }

    /// `present(_:awaiting:)` suspends until the registration sub-flow
    /// hands a `User` back with `dismissCoordinator(returning:)`. Any
    /// other dismissal — a swipe, a cancel — resumes with `nil`, so the
    /// cancelled path needs no extra channel.
    func showRegistration() {
        Task {
            let registered = await present(
                .registration,
                as: .sheet,
                awaiting: User.self
            )

            if let registered {
                ancestor(ofType: MainCoordinator.self)?.signIn(registered)
            } else {
                toasts.showNeutral("Registration cancelled")
            }
        }
    }

    func sendPasswordReset(to username: String) {
        Task {
            isWorking = true
            defer { isWorking = false }
            do {
                try await services.sendPasswordReset(to: username)
                popToRoot()
                toasts.show("Reset link sent to \(username)", symbol: "envelope.badge.fill")
            } catch {
                toasts.showWarning(error.localizedDescription)
            }
        }
    }
}
