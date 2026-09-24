import SwiftUI
import Scaffolding

/// One destination reached four different ways — pushed, presented as a
/// sheet, presented as a cover, installed as a root — that labels itself
/// correctly in all of them by reading `\.destination`.
///
/// It carries no navigation container of its own. When it is pushed it
/// sits inside the flow's existing `NavigationStack`; when it is
/// presented, the sheet is the container. Wrapping it in a
/// `NavigationStack` would break the parent's routing.
struct TestbedLeafScreen: View {
    @Environment(TestbedCoordinator.self) private var coordinator: TestbedCoordinator?
    @Environment(\.destination) private var destination
    @Environment(\.dismiss) private var dismiss

    let label: String
    var isLocked = false

    private var isModal: Bool { destination.routeType.isModal }

    var body: some View {
        DetailForm {
            Section("This screen") {
                LabeledContent("label", value: label)
                LabeledContent("routeType", value: caseLabel(destination.routeType))
                LabeledContent("presentationType", value: caseLabel(destination.presentationType))
                LabeledContent("meta", value: caseLabel(destination.meta))
            }

            Section("Its flow") {
                LabeledContent("generation", value: "#\(coordinator?.generation ?? 0)")
                LabeledContent("depth", value: "\(coordinator?.depth ?? 0)")
            }

            Section {
                if let coordinator, coordinator.isRootSwapped {
                    // This screen *is* the flow's root, because setRoot put
                    // it here — so there is nothing to dismiss back to, and
                    // the testbed that would swap it back no longer exists.
                    // The way home has to live here.
                    CallRow("setRoot(.testbed) — bring the testbed back",
                            symbol: "arrow.uturn.backward") { coordinator.restoreRoot() }
                } else {
                    if isLocked {
                        InfoText("Interactive dismissal is off: only the "
                                 + "presenter can close this one.",
                                 symbol: "lock.fill")
                    } else {
                        // @Environment(\.dismiss) works for both pops and
                        // modal dismissals, because Scaffolding wraps
                        // NavigationStack.
                        CallRow(isModal ? "dismiss()" : "dismiss() — back",
                                symbol: isModal ? "xmark" : "chevron.left") { dismiss() }
                    }

                    if isModal, let coordinator {
                        // Presenter-side dismissal, driven from the modal
                        // because that is the only thing on screen right
                        // now — a button on the presenting screen would be
                        // covered exactly when it became useful.
                        CallRow("presenter.dismissModal()",
                                symbol: "xmark.circle") {
                            coordinator.dismissModal()
                        }
                        CallRow("presenter.dismissAllModals()",
                                symbol: "xmark.circle.fill") {
                            coordinator.dismissAllModals()
                        }
                    }
                }
            } footer: {
                if let coordinator, coordinator.isRootSwapped {
                    Text("A root swap tears down everything above it, including "
                         + "the screen you tapped the button on. Anything that "
                         + "undoes a navigation call has to outlive it.")
                }
            }
        }
        .navigationTitle(label)
        .navigationBarTitleDisplayMode(.inline)
    }
}
