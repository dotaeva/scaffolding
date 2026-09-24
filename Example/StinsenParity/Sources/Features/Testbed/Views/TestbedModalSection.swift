import SwiftUI
import Scaffolding

struct TestbedModalSection: View {
    @Environment(TestbedCoordinator.self) private var coordinator

    var body: some View {
        Section {
            CallRow("present(.sheet) — native view modifiers",
                    symbol: "rectangle.portrait.bottomhalf.filled") { coordinator.presentScreen() }
            CallRow("present(.screen, as: .fullScreenCover)",
                    symbol: "rectangle.portrait.fill") { coordinator.presentCover() }
            CallRow("present(.lockedSheet) — swipe disabled by the view",
                    symbol: "lock.fill") { coordinator.presentLockedSheet() }
            CallRow("present(…) twice — then dismissAllModals()",
                    symbol: "square.on.square") { coordinator.presentStackedSheets() }
            CallRow("present(.childTestbed) — a modal coordinator",
                    symbol: "square.stack.3d.up.fill") { coordinator.presentChild() }
        } header: {
            Text("Modals")
        } footer: {
            Text("The presented view applies SwiftUI's sheet modifiers. "
                 + "A modal *coordinator* brings "
                 + "its own stack, so the testbed inside the sheet pushes "
                 + "independently of this one. The last two rows hand their "
                 + "dismissal back on a toast — a sheet covers the buttons "
                 + "that would otherwise close it.")
        }
    }
}
