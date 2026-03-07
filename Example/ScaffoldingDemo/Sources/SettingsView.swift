import SwiftUI
import Scaffolding

struct SettingsView: View {
    @Environment(AppCoordinator.self) private var coordinator

    var body: some View {
        NavigationStack {
            List {
                Section("General") {
                    Label("Appearance", systemImage: "paintbrush")
                    Label("Notifications", systemImage: "bell")
                }
                Section("About") {
                    Label("Version 1.0", systemImage: "info.circle")
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        coordinator.dismissCoordinator()
                    }
                }
            }
        }
    }
}
