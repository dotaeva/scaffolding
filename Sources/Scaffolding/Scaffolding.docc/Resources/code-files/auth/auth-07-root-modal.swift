import SwiftUI
import Scaffolding

@Scaffoldable @Observable
final class AppRootCoordinator: @MainActor RootCoordinatable {
    var root = Root<AppRootCoordinator>(root: .login)

    func login() -> any Coordinatable { LoginCoordinator() }
    func main() -> any Coordinatable { AppCoordinator() }

    // A view-only route presented above whatever the current root is.
    func whatsNew() -> some View { WhatsNewSheet() }

    func signIn() {
        setRoot(.main)
        // isRoot compares by Meta — handy for guards and one-shot UI.
        if isRoot(.main) {
            present(.whatsNew, as: .sheet(detents: [.medium]), policy: .distinct)
        }
    }

    func signOut() {
        // Close anything floating above the root before swapping it out.
        dismissAllModals()
        setRoot(.login)
    }
}
