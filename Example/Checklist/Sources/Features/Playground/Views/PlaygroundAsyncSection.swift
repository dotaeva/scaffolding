import SwiftUI
import Scaffolding

struct PlaygroundAsyncSection: View {
    @Environment(PlaygroundCoordinator.self) private var coordinator

    var body: some View {
        Section {
            Button("await routeAndWait(to: .leaf)") { coordinator.routeAndWaitLeaf() }
            Button("await present(.sheet, awaiting: Void.self)") { coordinator.presentAndWaitSheet() }
            Button("await present(.picker, awaiting: Int.self)") { coordinator.awaitPicker() }
            // Repeated from the State grid on purpose: this list is taller
            // than the screen, so by the time these buttons are reachable
            // the grid is scrolled off — and a call that resumed silently
            // looks exactly like one that never resumed.
            LabeledContent("last result") {
                Text(coordinator.lastResult ?? "—")
                    .font(.callout.monospaced())
            }
        } header: {
            Text("Awaited navigation")
        } footer: {
            Text("Each suspends until its destination leaves, then writes the "
                 + "outcome into “last result” — the row above, mirrored in "
                 + "the State grid at the top. The picker hands a value back "
                 + "with dismissCoordinator(returning:); cancelling it "
                 + "resumes with nil.")
        }
    }
}
