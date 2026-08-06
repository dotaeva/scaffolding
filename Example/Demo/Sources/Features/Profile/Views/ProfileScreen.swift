import SwiftUI
import Scaffolding

struct ProfileScreen: View {
    @Environment(ProfileCoordinator.self) private var coordinator
    // Every ancestor coordinator is injected too — the app root is readable
    // from any depth. Prefer the nearest coordinator; reach for an ancestor
    // only for actions that belong to it (root swaps, root-level modals).
    @Environment(AppCoordinator.self) private var appCoordinator

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 4) {
                VStack(spacing: 10) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 72))
                        .foregroundStyle(.white.opacity(0.85))
                    Text("Alex Rivera")
                        .font(.title3.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)

                row("Developer", "hammer") {
                    coordinator.openDeveloper()
                }
                row("What's new", "sparkles") {
                    // Modal above the whole root — not owned by any tab/flow.
                    appCoordinator.showWhatsNew()
                }
                row("Sign out", "rectangle.portrait.and.arrow.right") {
                    // Root swap: the entire main tree is torn down.
                    appCoordinator.signOut()
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
        }
        .background(ScreenBackground())
        .statusBarScrim()
        .toolbar(.hidden, for: .navigationBar)
    }

    private func row(_ title: String, _ systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            IconRow(title: title, systemImage: systemImage)
        }
        .buttonStyle(.plain)
    }
}
