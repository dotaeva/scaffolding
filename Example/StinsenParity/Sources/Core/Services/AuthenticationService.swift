import Foundation
import Observation

/// Where the signed-in user is persisted. It holds no navigation state —
/// swapping the root is `MainCoordinator`'s job, and this service only
/// remembers who is signed in across launches.
@MainActor
@Observable
final class AuthenticationService {
    private let defaults: UserDefaults
    private let key = "parity.user"

    private(set) var currentUser: User?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: key) {
            currentUser = try? JSONDecoder().decode(User.self, from: data)
        }
    }

    func signIn(_ user: User) {
        currentUser = user
        defaults.set(try? JSONEncoder().encode(user), forKey: key)
    }

    func signOut() {
        currentUser = nil
        defaults.removeObject(forKey: key)
    }
}
