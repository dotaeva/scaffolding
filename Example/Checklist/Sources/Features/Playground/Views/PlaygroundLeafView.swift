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
            Section("Flow") {
                LabeledContent("depth", value: "\(coordinator?.depth ?? 0)")
                Button("pop() — or use the back button") { dismiss() }
            }
        }
        .navigationTitle(label)
    }
}
