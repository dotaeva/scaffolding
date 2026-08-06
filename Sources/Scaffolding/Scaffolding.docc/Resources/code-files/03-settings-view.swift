import SwiftUI
import Scaffolding

struct SettingsView: View {
    @Environment(AppCoordinator.self) private var coordinator

    var body: some View {
        // No NavigationStack here: the flow coordinator already provides
        // one, and nesting a second stack inside a flow breaks routing.
        VStack(spacing: 0) {
            HStack {
                Text("Settings").font(.headline)
                Spacer()
                // A view-only modal has no coordinator of its own, so the
                // presenter closes it. SwiftUI's @Environment(\.dismiss)
                // works here too.
                Button("Done") { coordinator.dismissModal() }
            }
            .padding()

            List {
                Section("General") {
                    Label("Appearance", systemImage: "paintbrush")
                    Label("Notifications", systemImage: "bell")
                }
                Section("About") {
                    Label("Version 1.0", systemImage: "info.circle")
                }
            }
        }
    }
}
