import SwiftUI
import Scaffolding

@main
struct WeatherApp: App {
    @State private var coordinator = AppCoordinator()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            // Mounting the root coordinator's view is the only wiring an
            // entry point needs — the whole tree hangs off it.
            coordinator.view
                .environment(coordinator.store)
                .preferredColorScheme(.dark)
                // weather://location/lisbon · weather://day/3
                .onOpenURL { coordinator.handle($0) }
                // iOS: shake (⌃⌘Z in the simulator) → coordinator tree.
                .onShake { coordinator.showHierarchyDump() }
                .task { coordinator.restoreNavigationState() }
                .onChange(of: scenePhase) { _, phase in
                    guard phase == .background || phase == .inactive else { return }
                    coordinator.saveNavigationState()
                }
        }
        #if os(macOS)
        .defaultSize(width: 1_050, height: 720)
        .commands {
            // Standard View → Show/Hide Sidebar item; the split
            // coordinator's toggleSidebar() backs the toolbar button.
            SidebarCommands()
            CommandMenu("Debug") {
                Button("Coordinator Tree") { coordinator.showHierarchyDump() }
                    .keyboardShortcut("d", modifiers: [.command, .shift])
            }
        }
        #endif
    }
}
