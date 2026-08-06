import SwiftUI
import Scaffolding

@main
struct PlanetsApp: App {
    @State private var coordinator = AppCoordinator()

    var body: some Scene {
        WindowGroup {
            // The tab coordinator is the top of the tree now; each tab's
            // flow brings its own NavigationStack.
            coordinator.view
        }
    }
}
