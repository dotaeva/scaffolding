import SwiftUI
import Scaffolding

/// Orientation surface: where this screen sits in the tree, from both
/// sides. The two routeTypes answer different questions and diverge here —
/// on the split layout the flow reads .sheet while the screen reads .root.
struct SettingsDebugSection: View {
    @Environment(SettingsCoordinator.self) private var coordinator
    @Environment(\.destination) private var destination

    var body: some View {
        Section("Orientation") {
            LabeledContent(
                "destination.routeType",
                value: ".\(String(describing: destination.routeType))"
            )
            LabeledContent(
                "destination.presentationType",
                value: ".\(String(describing: destination.presentationType))"
            )
            LabeledContent(
                "destination.meta",
                value: ".\(String(describing: destination.meta))"
            )
            LabeledContent(
                "flow.routeType",
                value: ".\(String(describing: coordinator.routeType))"
            )
            LabeledContent(
                "isPresentingModal",
                value: String(coordinator.isPresentingModal)
            )
            Button("Coordinator Tree") {
                coordinator.showTree()   // pushed here; the shake shows it as a sheet
            }
            Button("Dismiss All Modals") {
                coordinator.closeAllModals()
            }
        }
    }
}
