import SwiftUI
import Scaffolding

/// Orientation surface: where this screen sits in the tree, read from both
/// sides. The two `routeType`s answer different questions and diverge on
/// iPad/Mac, where the flow is a sheet but its root screen is a root.
struct SettingsDebugSection: View {
    @Environment(SettingsCoordinator.self) private var coordinator
    @Environment(\.destination) private var destination

    var body: some View {
        Section("Orientation") {
            LabeledContent("destination.routeType", value: caseLabel(destination.routeType))
            LabeledContent("destination.meta", value: caseLabel(destination.meta))
            LabeledContent("flow.routeType", value: caseLabel(coordinator.routeType))
            LabeledContent("flow.depth", value: "\(coordinator.depth)")
            LabeledContent("isPresentingModal", value: String(coordinator.isPresentingModal))
            Button("Coordinator Tree") { coordinator.showTree() }
            Button("Dismiss All Modals") { coordinator.closeAllModals() }
        }
    }
}
