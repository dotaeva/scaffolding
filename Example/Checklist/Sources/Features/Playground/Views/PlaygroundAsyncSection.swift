import SwiftUI
import Scaffolding

struct PlaygroundAsyncSection: View {
    @Environment(PlaygroundCoordinator.self) private var coordinator

    var body: some View {
        Section {
            Button("await routeAndWait(to: .leaf)") { coordinator.routeAndWaitLeaf() }
            Button("await presentAndWait(.sheet)") { coordinator.presentAndWaitSheet() }
            Button("await present(.picker, awaiting: Int.self)") { coordinator.awaitPicker() }
        } header: {
            Text("Awaited navigation")
        } footer: {
            Text("Each suspends until its destination leaves, then writes the "
                 + "outcome into “last result” above. The picker hands a value "
                 + "back with dismissCoordinator(returning:); cancelling it "
                 + "resumes with nil.")
        }
    }
}
