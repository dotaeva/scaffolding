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
                    if let data = try? coordinator.captureNavigationState() {
                        UserDefaults.standard.set(data, forKey: "nav-state")
                    }
                }
                .task {
                    // Restore onto a FRESHLY created coordinator: restoration
                    // replays routes through the normal route/present/setRoot
                    // machinery rather than replacing state wholesale.
                    guard let data = UserDefaults.standard.data(forKey: "nav-state") else { return }
                    try? coordinator.restoreNavigationState(from: data)
                }
        }
    }
}
