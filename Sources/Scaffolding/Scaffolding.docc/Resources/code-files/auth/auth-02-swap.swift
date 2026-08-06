import SwiftUI
import Scaffolding

@Scaffoldable @Observable
final class AppRootCoordinator: @MainActor RootCoordinatable {
    var root = Root<AppRootCoordinator>(root: .login)

    init() {
        // Default animation for every swap; setRoot(_:animation:) can
        // override it per call.
        setRootTransitionAnimation(.smooth(duration: 0.35))
    }

    func login() -> any Coordinatable { LoginCoordinator() }
    func main() -> any Coordinatable { AppCoordinator() }

    // Void helpers are never tracked by the macro.
    func signIn() {
        setRoot(.main)
    }

    func signOut() {
        setRoot(.login, animation: .easeInOut(duration: 0.25))
    }
}
