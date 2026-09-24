import SwiftUI
import Scaffolding

struct TestbedAwaitSection: View {
    @Environment(TestbedCoordinator.self) private var coordinator

    var body: some View {
        Section {
            CallRow("await routeAndWait(to: .screen)",
                    symbol: "clock.arrow.trianglehead.counterclockwise.rotate.90") { coordinator.awaitPush() }
            CallRow("await present(.sheet, awaiting: Void.self)",
                    symbol: "hourglass") { coordinator.awaitSheet() }
            CallRow("await present(.picker, awaiting: Int.self)",
                    symbol: "arrow.uturn.backward.circle") { coordinator.awaitPicker() }
        } header: {
            Text("Awaited navigation")
        } footer: {
            Text("Each call suspends until its destination leaves, then toasts "
                 + "the outcome — the screen that started it is usually gone by "
                 + "then, which is exactly why the result is reported from the "
                 + "coordinator rather than the view.")
        }
    }
}
