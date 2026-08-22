import SwiftUI
import Scaffolding

@main
struct SolarSystemApp: App {
    @State private var coordinator = SolarSystemCoordinator()

    var body: some Scene {
        WindowGroup {
            // Mounting the root coordinator's view is the only wiring the
            // entry point needs. On iPad and Mac this renders the split
            // view; on iPhone (compact width) the same tree collapses to a
            // single stack — nothing is lost when the size class changes,
            // because all navigation state lives on the coordinator.
            coordinator.view
        }
    }
}
