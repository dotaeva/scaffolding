import Foundation

enum AuthError: LocalizedError {
    case emptyCredentials
    case unknownUser

    var errorDescription: String? {
        switch self {
        case .emptyCredentials: "Enter a username and a password."
        case .unknownUser: "We don't recognise that username."
        }
    }
}

/// The fake backend. Every call is `async` so the coordinators have
/// something real to `await` — which is what makes the awaited navigation
/// and the loading toasts worth demonstrating.
struct UnauthenticatedServices: Sendable {
    var latency: Duration = .milliseconds(600)

    func login(username: String, password: String) async throws -> User {
        guard !username.isEmpty, !password.isEmpty else { throw AuthError.emptyCredentials }
        try await Task.sleep(for: latency)
        return User(username: username, accessToken: UUID().uuidString)
    }

    func register(username: String, password: String) async throws -> User {
        guard !username.isEmpty, !password.isEmpty else { throw AuthError.emptyCredentials }
        try await Task.sleep(for: latency)
        return User(username: username, accessToken: UUID().uuidString)
    }

    func sendPasswordReset(to username: String) async throws {
        guard !username.isEmpty else { throw AuthError.unknownUser }
        try await Task.sleep(for: latency)
    }
}
