import SwiftUI
import Combine
import Scaffolding

@main
struct DemoApp: App {
    @State private var coordinator = AppCoordinator()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            // Mounting the root coordinator's view is the only wiring an
            // entry point needs — the whole tree hangs off it.
            coordinator.view
                .preferredColorScheme(.dark)
                // Deep links: scaffolding-demo://holding/NVDA,
                // scaffolding-demo://transaction/2
                .onOpenURL { coordinator.handle($0) }
                // Shake (⌃⌘Z in the simulator) → coordinator-tree dump.
                .onReceive(NotificationCenter.default.publisher(for: .deviceDidShake)) { _ in
                    coordinator.showHierarchyDump()
                }
                .task {
                    // Replay the last captured navigation tree onto the
                    // freshly created coordinator. Coordinators that don't
                    // opt into codable (InvestCoordinator — closure payloads)
                    // restore at their initial position; routes that no
                    // longer decode are skipped, not fatal.
                    if let data = UserDefaults.standard.data(forKey: "nav-state") {
                        try? coordinator.restoreNavigationState(from: data)
                    }
                }
                .onChange(of: scenePhase) { _, phase in
                    guard phase == .background else { return }
                    // Capture walks the whole tree from the coordinator it's
                    // called on. The Data is opaque — persist it anywhere.
                    UserDefaults.standard.set(
                        try? coordinator.captureNavigationState(),
                        forKey: "nav-state"
                    )
                }
        }
    }
}
