import SwiftUI
import Scaffolding

/// The pushed child coordinator's screen: it pushes onto the shared stack,
/// finds its ancestor, and dismisses *itself* rather than one screen.
struct PlaygroundChildView: View {
    @Environment(PlaygroundChildCoordinator.self) private var coordinator
    // Every ancestor is injected too, from any depth.
    @Environment(PlaygroundCoordinator.self) private var parent: PlaygroundCoordinator?

    var body: some View {
        List {
            Section {
                LabeledContent("child depth", value: "\(coordinator.depth)")
                LabeledContent("parent depth", value: "\(parent?.depth ?? 0)")
                LabeledContent(
                    "ancestor(ofType:)",
                    value: coordinator.ancestor(ofType: PlaygroundCoordinator.self) == nil
                        ? "nil" : "found"
                )
            } header: {
                Text("A child coordinator")
            } footer: {
                Text("A pushed child shares its parent's NavigationStack, so "
                     + "its own pushes continue the same stack.")
            }

            Section {
                Button("route(to: .grandchild)") { coordinator.pushGrandchild() }
                Button("dismissCoordinator() — removes the whole child") {
                    coordinator.dismissCoordinator()
                }
            }
        }
        .navigationTitle("Child")
    }
}
