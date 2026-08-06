import SwiftUI
import Scaffolding

// A RootCoordinatable owns one destination at a time and swaps it whole —
// there is no "back" between login and the signed-in app.
@Scaffoldable @Observable
final class AppRootCoordinator: @MainActor RootCoordinatable {
    var root = Root<AppRootCoordinator>(root: .login)

    func login() -> any Coordinatable { LoginCoordinator() }
    func main() -> any Coordinatable { AppCoordinator() }
}
