import SwiftUI
import Scaffolding

@main
struct PlanetsApp: App {
    @State private var coordinator = AppRootCoordinator()

    var body: some Scene {
        WindowGroup {
            coordinator.view
                .onOpenURL { coordinator.handle($0) }
                // Push payloads, quick actions, and Handoff all funnel into
                // the same coordinator entry point — one implementation of
                // "where should the app be", not one per source.
                .onReceive(NotificationCenter.default.publisher(for: .didTapPush)) { note in
                    if let url = note.object as? URL {
                        coordinator.handle(url)
                    }
                }
        }
    }
}
