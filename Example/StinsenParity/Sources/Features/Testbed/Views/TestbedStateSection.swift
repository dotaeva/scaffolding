import SwiftUI
import Scaffolding

/// Everything the orientation API can say about this flow, live.
///
/// Plain key/value rows, the way Settings ▸ General ▸ About lists a
/// machine's facts. A grid of bespoke tiles was denser but it was also the
/// only thing on screen that looked designed rather than built.
struct TestbedStateSection: View {
    @Environment(TestbedCoordinator.self) private var coordinator
    @Environment(\.destination) private var destination

    /// The Stinsen screen's text field: type here, push a few screens,
    /// come back. Each generation keeps its own state because each is a
    /// separate coordinator with its own view.
    @State private var scratch = ""

    var body: some View {
        Section {
            ReadoutRow("generation", "#\(coordinator.generation)")
            ReadoutRow("depth", "\(coordinator.depth)")
            ReadoutRow("topDestination", caseLabel(coordinator.topDestination))
            ReadoutRow("count(.screen)", "\(coordinator.count(of: .screen))")
            ReadoutRow("isInStack(.childTestbed)", String(coordinator.isInStack(.childTestbed)))
            ReadoutRow("isPresentingModal", String(coordinator.isPresentingModal))
            ReadoutRow("flow.routeType", caseLabel(coordinator.routeType))
            ReadoutRow("screen.routeType", caseLabel(destination.routeType))
            ReadoutRow("onDismiss count", "\(coordinator.dismissals)")

            LabeledContent("Scratch") {
                // `prompt:`, not the title initialiser — inside a
                // LabeledContent the title argument is drawn as a *second*
                // label beside the field instead of as placeholder text.
                TextField("", text: $scratch, prompt: Text("Survives a push and pop"))
                    // LabeledContent aligns its trailing content to the
                    // right, which would right-align the text you type.
                    .multilineTextAlignment(.leading)
            }

            CallRow("resetReadouts()", symbol: "arrow.counterclockwise") {
                coordinator.resetReadouts()
            }
        } header: {
            Text("State")
        } footer: {
            Text("“generation” counts testbed coordinators, not screens: "
                 + "present or push a child testbed and the copy inside it "
                 + "reports #\(coordinator.generation + 1).")
        }
    }
}
