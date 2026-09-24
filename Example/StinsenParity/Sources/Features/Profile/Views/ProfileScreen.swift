import SwiftUI
import Scaffolding

struct ProfileScreen: View {
    @Environment(ProfileCoordinator.self) private var coordinator

    let user: User
    let store: TodosStore

    var body: some View {
        DetailForm {
            Section {
                identity
                ReadoutRow("tasks", "\(store.all.count)")
                ReadoutRow("favourites", "\(store.favorites.count)")
            }

            Section {
                ShellRows()
                ReadoutRow("flow.routeType", caseLabel(coordinator.routeType))
            } header: {
                Text("Where am I?")
            }

            Section {
                Button("Sign Out…", role: .destructive) { coordinator.signOut() }
            } footer: {
                Text("Signing out swaps the root of the whole tree. There is no "
                     + "back button out of it, and the shell below is torn down "
                     + "with it — tabs on iPhone, columns on iPad and Mac.")
            }
        }
        .navigationTitle("Profile")
    }

    /// The Apple-Account-row shape: a mark, a name, a status line.
    private var identity: some View {
        HStack(spacing: 11) {
            AccountAvatar(size: 38)

            VStack(alignment: .leading, spacing: 1) {
                Text(user.username)
                Text("Signed in")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 3)
    }
}
