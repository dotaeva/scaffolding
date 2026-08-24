import SwiftUI
import Scaffolding

/// Every push and pop variant, live against the flow that owns this
/// screen. Push it repeatedly to build a stack, then watch the readouts
/// while the pop family takes it apart.
struct PlaygroundView: View {
    @Environment(SettingsCoordinator.self) private var coordinator

    var body: some View {
        List {
            Section {
                // Renders only when this screen itself was presented — a
                // view-only modal has no navigation bar to host a button.
                ModalDismissButton()
            }

            Section("State") {
                LabeledContent("depth", value: "\(coordinator.depth)")
                LabeledContent("topDestination", value: caseLabel(coordinator.topDestination))
                LabeledContent("count(of: .playground)", value: "\(coordinator.count(of: .playground))")
                LabeledContent("isInStack(.about)", value: String(coordinator.isInStack(.about)))
            }

            Section("Push") {
                Button("route(to: .playground)") { coordinator.pushAnotherPlayground() }
                Button("replaceLast(with: .playground)") {
                    // Swaps the top screen, so back skips the one replaced.
                    coordinator.replaceLast(with: .playground)
                }
                Button("present(.playground, as: .sheet)") {
                    // The same route, presented instead of pushed — the
                    // presenter picks, the screen never knows.
                    coordinator.present(.playground, as: .sheet(detents: [.medium, .large]))
                }
            }

            Section("Pop") {
                Button("pop()") { coordinator.pop() }
                if coordinator.depth >= 2 {
                    Button("pop(2)") { coordinator.pop(2) }
                }
                Button("popToRoot()") { coordinator.popToRoot() }
                if coordinator.count(of: .playground) >= 2 {
                    Button("popToFirst(.playground)") { coordinator.popToFirst(.playground) }
                    Button("popToLast(.playground)") { coordinator.popToLast(.playground) }
                }
            }
        }
        .navigationTitle("Playground")
    }
}
