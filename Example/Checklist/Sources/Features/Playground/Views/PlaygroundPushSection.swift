import SwiftUI
import Scaffolding

struct PlaygroundPushSection: View {
    @Environment(PlaygroundCoordinator.self) private var coordinator

    var body: some View {
        Section {
            Button("route(to: .playground)") { coordinator.push() }
            Button("route(to: .leaf) + onDismiss") { coordinator.pushLeaf() }
            Button("route(to: .leaf, policy: .distinct)") { coordinator.pushLeafDistinct() }
            Button("route(to: .child) — a child coordinator") { coordinator.pushChild() }
            Button("replaceLast(with: .leaf)") { coordinator.replaceTop() }
            Button("setRoot(.leaf)") { coordinator.swapRoot() }
        } header: {
            Text("Push & replace")
        } footer: {
            Text("Tap the .distinct row twice: the second tap is skipped "
                 + "because the same case is already on top. setRoot replaces "
                 + "this very screen, so the button that swaps the playground "
                 + "back is on the new root — not here, where it could never "
                 + "be reached.")
        }
    }
}
