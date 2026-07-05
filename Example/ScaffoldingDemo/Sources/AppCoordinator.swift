import SwiftUI
import Scaffolding

struct AuthToken: Sendable, Equatable {
    let username: String
}

@MainActor @Observable @Scaffoldable
final class AppCoordinator: @MainActor FlowCoordinatable {
    var stack = FlowStack<AppCoordinator>(root: .home)

    var session: AuthToken?
    var lastSettingsAction: String?

    // MARK: - Routes

    func home() -> some View { HomeView() }

    func detail(id: String) -> some View { DetailView(id: id) }

    func settings() -> some View {
        NavigationStack {
            SettingsView()
                .navigationTitle("Settings")
        }
    }

    func login(onComplete: @escaping @MainActor (AuthToken) -> Void) -> any Coordinatable {
        LoginCoordinator(onComplete: onComplete)
    }

    // MARK: - Flow primitives

    /// Push a detail screen for the given item.
    func openDetail(id: String) {
        route(to: .detail(id: id))
    }

    /// Present settings as a flow-sheet. The dismissal callback fires
    /// on both Save (programmatic dismiss) and Cancel/swipe.
    func openSettings(savedAction: @escaping @MainActor (String) -> Void) {
        present(.settings, as: .sheet, onDismiss: { [weak self] in
            if let action = self?.lastSettingsAction {
                savedAction(action)
                self?.lastSettingsAction = nil
            }
        })
    }

    /// Present the login flow as a sheet. The result (an `AuthToken`)
    /// is delivered via the `onComplete` callback embedded in the
    /// route definition — classic coordinator pattern, no async needed.
    func startLoginFlow() {
        present(.login(onComplete: { [weak self] token in
            self?.session = token
        }), as: .sheet)
    }

    func signOut() {
        session = nil
    }
}
