import SwiftUI
import Scaffolding

@main
struct ScaffoldingDemoApp: App {
    @State private var coordinator = AppCoordinator()

    var body: some Scene {
        WindowGroup {
            coordinator.view()
        }
    }
}
