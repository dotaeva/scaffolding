import SwiftUI
import Scaffolding

struct PlaygroundModalSection: View {
    @Environment(PlaygroundCoordinator.self) private var coordinator

    var body: some View {
        Section {
            Button("present(.sheet, detents: [.medium, .large])") {
                coordinator.presentSheet()
            }
            Button("present(.cover, as: .fullScreenCover)") {
                coordinator.presentCover()
            }
            Button("present(.sheet, interactiveDismissDisabled: true)") {
                coordinator.presentLockedSheet()
            }
            Button("dismissModal()") { coordinator.dismissModal() }
            Button("dismissAllModals()") { coordinator.dismissAllModals() }
        } header: {
            Text("Modals")
        } footer: {
            Text("The presenter chooses the chrome, and dismissModal() is how "
                 + "it closes a view-only modal — there is no coordinator "
                 + "inside one to dismiss itself. On macOS a cover becomes a "
                 + "sheet, while the state still reports .fullScreenCover.")
        }
    }
}
