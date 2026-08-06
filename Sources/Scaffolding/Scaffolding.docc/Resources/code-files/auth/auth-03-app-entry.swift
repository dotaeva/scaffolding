import SwiftUI
import Scaffolding

@main
struct PlanetsApp: App {
    @State private var coordinator = AppRootCoordinator()

    var body: some Scene {
        WindowGroup {
            // The root coordinator is now the top of the tree: it renders
            // either the login flow or the tab coordinator.
            coordinator.view
        }
    }
}
