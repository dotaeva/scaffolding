import SwiftUI
import Scaffolding

@main
struct PlanetsApp: App {
    @State private var coordinator = AppRootCoordinator()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            coordinator.view
                .onChange(of: scenePhase) { _, phase in
                    guard phase == .background else { return }
                    // Walks the whole tree from this coordinator down: the
                    // current root, tab selection, every flow's stack, and
                    // presented modals. Treat the Data as opaque.
                    if let data = try? coordinator.captureNavigationState() {
                        UserDefaults.standard.set(data, forKey: "nav-state")
                    }
                }
        }
    }
}
