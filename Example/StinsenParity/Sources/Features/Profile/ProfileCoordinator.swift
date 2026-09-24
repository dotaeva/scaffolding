import SwiftUI
import Scaffolding

@MainActor
@Observable
@Scaffoldable
final class ProfileCoordinator: @MainActor FlowCoordinatable {
    var stack = FlowStack<ProfileCoordinator>(root: .profile)

    let user: User
    let store: TodosStore

    init(user: User, store: TodosStore) {
        self.user = user
        self.store = store
    }

    // MARK: Routes

    func profile() -> some View { makeProfile() }
}

// MARK: - Factory

extension ProfileCoordinator {
    func makeProfile() -> some View { ProfileScreen(user: user, store: store) }
}

// MARK: - Session

extension ProfileCoordinator {
    /// Signing out belongs to the app root, three coordinators up.
    /// `ancestor(ofType:)` walks the parent chain to it — the view never
    /// reaches across the tree itself.
    func signOut() {
        ancestor(ofType: MainCoordinator.self)?.signOut()
    }
}
