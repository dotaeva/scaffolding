import SwiftUI
import Scaffolding

struct SettingsScreen: View {
    @Environment(SettingsCoordinator.self) private var coordinator
    // Present only in the tab layout — optional, so the same screen also
    // works as a sheet on the split layout.
    @Environment(MainTabCoordinator.self) private var tabs: MainTabCoordinator?
    @Environment(WeatherStore.self) private var store

    var body: some View {
        Form {
            Section("Preferences") {
                LabeledContent("Units", value: store.units.label)
                Button("Change Units…") {
                    coordinator.changeUnits()   // awaits the picker's result
                }
            }

            if let tabs {
                Section("Tabs") {
                    Toggle("Radar tab", isOn: radarBinding(tabs))
                    LabeledContent(
                        "isInTabItems(.radar)",
                        value: String(tabs.isInTabItems(.radar))
                    )
                }
            }

            SettingsSplitSection()

            Section("Data") {
                Button("Refresh All Data") {
                    coordinator.refreshAll()    // presenter-closed overlay
                }
            }

            SettingsDebugSection()

            Section {
                Button("About This Example") {
                    coordinator.showAbout()
                }
                Button("Reset Onboarding", role: .destructive) {
                    // Reaches the app root via ancestor(ofType:).
                    coordinator.resetOnboarding()
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Settings")
        .toolbar {
            // This screen is the *root* of the settings flow, so its own
            // \.destination reads .root even when the flow is a sheet —
            // the flow's routeType is the value that knows (the two
            // diverge; see the Orientation section below).
            if coordinator.routeType.isModal {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { coordinator.dismissCoordinator() }
                }
            }
        }
    }

    private func radarBinding(_ tabs: MainTabCoordinator) -> Binding<Bool> {
        Binding(
            get: { store.radarTabEnabled },
            set: { enabled in
                store.radarTabEnabled = enabled
                tabs.setRadarTab(enabled: enabled)   // appendTab/removeFirstTab
            }
        )
    }
}
