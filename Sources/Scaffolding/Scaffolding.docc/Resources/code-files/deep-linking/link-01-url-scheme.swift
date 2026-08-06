import SwiftUI
import Scaffolding

@main
struct PlanetsApp: App {
    @State private var coordinator = AppRootCoordinator()

    var body: some Scene {
        WindowGroup {
            coordinator.view
                // Deep links enter the app in exactly one place and are
                // handed straight to the coordinator. Views never dispatch
                // multi-step navigation themselves.
                .onOpenURL { url in
                    coordinator.handle(url)
                }
        }
    }
}
