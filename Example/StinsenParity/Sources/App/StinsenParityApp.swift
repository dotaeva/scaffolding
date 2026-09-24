import SwiftUI
import Scaffolding

@main
struct StinsenParityApp: App {
    @State private var coordinator = MainCoordinator()

    var body: some Scene {
        WindowGroup {
            // Mounting the root coordinator's view is the only wiring an
            // entry point needs — the whole tree hangs off it.
            coordinator.view
                .environment(coordinator.toasts)
                // Once, at the root, so a toast survives the root swap
                // that tears down the screen which posted it — and, drawing
                // in its own window, stays reachable above a sheet.
                .toastPresentation(coordinator.toasts)
                // parity://todo/Buy%20milk
                .onOpenURL { coordinator.handle($0) }
        }
    }
}
