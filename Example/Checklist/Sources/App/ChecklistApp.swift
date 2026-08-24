import SwiftUI
import Scaffolding

@main
struct ChecklistApp: App {
    @State private var coordinator = AppCoordinator()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            // Mounting the root coordinator's view is the only wiring an
            // entry point needs — the whole tree hangs off it.
            coordinator.view
                .environment(coordinator.store)
                // checklist://today · checklist://list/work · checklist://todo/6
                .onOpenURL { coordinator.handle($0) }
                // iOS: shake (⌃⌘Z in the simulator) → coordinator tree.
                .onShake { coordinator.showHierarchy() }
                .task { coordinator.restoreNavigationState() }
                .onChange(of: scenePhase) { _, phase in
                    guard phase == .background || phase == .inactive else { return }
                    coordinator.saveNavigationState()
                }
        }
        #if os(macOS)
        .defaultSize(width: 1_080, height: 720)
        .commands {
            // The standard View ▸ Sidebar item; the split coordinator's
            // toggleSidebar() backs the toolbar button.
            SidebarCommands()
            CommandGroup(after: .newItem) {
                Button("New Task") { coordinator.newTodoCommand() }
                    .keyboardShortcut("n", modifiers: .command)
            }
            CommandMenu("Debug") {
                Button("Coordinator Tree") { coordinator.showHierarchy() }
                    .keyboardShortcut("d", modifiers: [.command, .shift])
            }
        }
        #endif
    }
}
