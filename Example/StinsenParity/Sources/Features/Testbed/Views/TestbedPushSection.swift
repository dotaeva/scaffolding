import SwiftUI
import Scaffolding

struct TestbedPushSection: View {
    @Environment(TestbedCoordinator.self) private var coordinator

    var body: some View {
        Section {
            CallRow("route(to: .screen) + onDismiss",
                    symbol: "arrow.right") { coordinator.pushScreen() }
            CallRow("route(to: .screen, policy: .distinct)",
                    symbol: "arrow.right.to.line") { coordinator.pushDistinct() }
            CallRow("route(to: .childTestbed) — a child coordinator",
                    symbol: "square.stack.3d.up") { coordinator.pushChild() }
            CallRow("replaceLast(with: .screen)",
                    symbol: "arrow.2.squarepath") { coordinator.replaceTop() }
            CallRow("setRoot(.screen)",
                    symbol: "arrow.triangle.2.circlepath") { coordinator.swapRoot() }
        } header: {
            Text("Push & replace")
        } footer: {
            Text("Tap the .distinct row twice: the second tap is skipped "
                 + "because the same case is already on top. A pushed child "
                 + "coordinator shares this NavigationStack — pushing a "
                 + "grandchild from inside it continues the same stack.")
        }
    }
}
