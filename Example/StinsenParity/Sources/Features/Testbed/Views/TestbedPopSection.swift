import SwiftUI
import Scaffolding

struct TestbedPopSection: View {
    @Environment(TestbedCoordinator.self) private var coordinator

    var body: some View {
        Section {
            CallRow("pop()", symbol: "arrow.left") { coordinator.pop() }
            if coordinator.depth >= 2 {
                CallRow("pop(2)", symbol: "arrow.left.to.line") { coordinator.pop(2) }
            }
            CallRow("popToRoot()", symbol: "house") { coordinator.popToRoot() }
            if coordinator.isInStack(.screen) {
                CallRow("popToFirst(.screen)",
                        symbol: "arrow.up.to.line") { coordinator.popToFirst(.screen) }
                CallRow("popToLast(.screen)",
                        symbol: "arrow.down.to.line") { coordinator.popToLast(.screen) }
            }
            CallRow("dismissCoordinator() — removes this whole testbed",
                    symbol: "xmark.circle", tint: .red) { coordinator.dismissSelf() }
                .disabled(!coordinator.canDismissSelf)
        } header: {
            Text("Pop & dismiss")
        } footer: {
            Text("Meta-based pops compare *cases*, not values — the .screen "
                 + "destinations differ only by label, so popToFirst lands on "
                 + "the earliest of them. dismissCoordinator() is greyed out "
                 + "here because a tab's root coordinator has no parent to be "
                 + "removed from; reach it from a pushed or presented testbed.")
        }
    }
}
