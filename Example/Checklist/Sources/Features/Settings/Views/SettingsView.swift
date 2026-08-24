import SwiftUI
import Scaffolding

struct SettingsView: View {
    @Environment(SettingsCoordinator.self) private var coordinator
    @State var viewModel: SettingsViewModel

    var body: some View {
        Form {
            Section("Preferences") {
                Toggle("Sort by due date", isOn: $viewModel.sortByDueDate)
                Toggle("Show completed tasks", isOn: $viewModel.showsCompleted)
                Button("Manage Tags…") { coordinator.showTags() }
            }

            // Each renders only in the shell that owns it — ancestors are
            // injected into the environment, so an optional read is all it
            // takes to adapt.
            SettingsShellSection()

            Section("Data") {
                LabeledContent("Tasks", value: "\(viewModel.taskCount)")
                LabeledContent("Lists", value: "\(viewModel.listCount)")
                Button("Sync Now") { coordinator.syncNow() }
                Button("Forget Saved Navigation") { coordinator.forgetNavigationState() }
            }

            SettingsDebugSection()

            Section {
                Button("About Checklist") { coordinator.showAbout() }
                Button("Restart Onboarding", role: .destructive) {
                    coordinator.restartOnboarding()
                }
            }
        }
        .formStyle(.grouped)
        #if os(iOS)
        .scrollEdgeEffectStyle(.hard, for: .top)
        #endif
        .navigationTitle("Settings")
        .toolbar {
            // This screen is the *root* of the settings flow, so its own
            // \.destination reads .root even when the flow is presented as
            // a sheet. The flow's routeType is what knows — the two answer
            // different questions (see the Orientation section).
            if coordinator.routeType.isModal {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { coordinator.dismissCoordinator() }
                }
            }
        }
    }
}

#Preview {
    SettingsCoordinator(store: TodoStore()).view
        .environment(TodoStore())
}
