import SwiftUI
import Scaffolding

/// A pushed leaf. It reads how it was reached from the environment, so the
/// same screen labels itself correctly whether it was pushed or awaited.
struct PlaygroundLeafView: View {
    @Environment(PlaygroundCoordinator.self) private var coordinator: PlaygroundCoordinator?
    @Environment(\.destination) private var destination
    @Environment(\.dismiss) private var dismiss

    let label: String

    var body: some View {
        List {
            Section("This screen") {
                LabeledContent("label", value: label)
                LabeledContent("routeType", value: caseLabel(destination.routeType))
                LabeledContent("meta", value: caseLabel(destination.meta))
            }
            Section {
                LabeledContent("depth", value: "\(coordinator?.depth ?? 0)")
                if let coordinator, coordinator.isRootSwapped {
                    // setRoot put this screen here, so there is nothing to
                    // pop back to and the playground that would swap it
                    // back is gone. The way home has to live here.
                    Button("setRoot(.playground) — bring the playground back") {
                        coordinator.restoreRoot()
                    }
                } else {
                    Button("pop() — or use the back button") { dismiss() }
                }
            } header: {
                Text("Flow")
            } footer: {
                if coordinator?.isRootSwapped == true {
                    Text("A root swap tears down everything above it, including "
                         + "the screen you tapped the button on — so anything "
                         + "that undoes one has to outlive it.")
                }
            }
        }
        .navigationTitle(label)
    }
}
