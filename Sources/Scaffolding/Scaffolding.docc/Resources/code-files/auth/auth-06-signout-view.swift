import SwiftUI
import Scaffolding

struct SettingsView: View {
    // Views read ancestors straight from the environment — Scaffolding
    // injects every coordinator above this screen, however deep it is.
    @Environment(AppRootCoordinator.self) private var appCoordinator

    var body: some View {
        List {
            Section("Account") {
                Button("Sign Out", role: .destructive) {
                    appCoordinator.signOut()
                }
            }
        }
    }
}
