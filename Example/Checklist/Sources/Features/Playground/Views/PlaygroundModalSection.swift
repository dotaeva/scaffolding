import SwiftUI
import Scaffolding

struct PlaygroundModalSection: View {
    @Environment(PlaygroundCoordinator.self) private var coordinator

    var body: some View {
        Section {
            Button("present(.sheet) — native view modifiers") {
                coordinator.presentSheet()
            }
            Button("present(.cover, as: .fullScreenCover)") {
                coordinator.presentCover()
            }
            Button("present(.lockedSheet) — swipe disabled by the view") {
                coordinator.presentLockedSheet()
            }
            Button("present(…) twice — one shows, one waits") {
                coordinator.presentTwoSheets()
            }
        } header: {
            Text("Modals")
        } footer: {
            Text("The presented view applies SwiftUI's sheet modifiers. dismissModal() is how "
                 + "it closes a view-only modal — there is no coordinator "
                 + "inside one to dismiss itself. Both dismissal buttons are "
                 + "on the modal itself: a presented sheet covers this screen, "
                 + "so a button here could never be tapped while there was "
                 + "anything to dismiss. On macOS a cover becomes a sheet, "
                 + "while the state still reports .fullScreenCover.")
        }
    }
}
