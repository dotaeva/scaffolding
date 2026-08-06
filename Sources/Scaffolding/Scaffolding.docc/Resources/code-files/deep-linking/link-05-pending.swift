import SwiftUI
import Scaffolding

@Scaffoldable @Observable
final class AppRootCoordinator: @MainActor RootCoordinatable {
    var root = Root<AppRootCoordinator>(root: .login)

    /// A link that arrived before the user signed in.
    var pendingURL: URL?

    func login() -> any Coordinatable { LoginCoordinator() }
    func main() -> any Coordinatable { AppCoordinator() }

    func signIn() {
        setRoot(.main)

        // Replay the deferred link once the tree exists.
        if let url = pendingURL {
            pendingURL = nil
            handle(url)
        }
    }

    func signOut() {
        dismissAllModals()
        setRoot(.login)
    }
}
