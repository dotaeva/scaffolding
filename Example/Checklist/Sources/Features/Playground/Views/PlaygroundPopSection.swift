import SwiftUI
import Scaffolding

struct PlaygroundPopSection: View {
    @Environment(PlaygroundCoordinator.self) private var coordinator

    var body: some View {
        Section {
            Button("pop()") { coordinator.pop() }
            if coordinator.depth >= 2 {
                Button("pop(2)") { coordinator.pop(2) }
            }
            Button("popToRoot()") { coordinator.popToRoot() }
            if coordinator.isInStack(.leaf) {
                Button("popToFirst(.leaf)") { coordinator.popToFirst(.leaf) }
                Button("popToLast(.leaf)") { coordinator.popToLast(.leaf) }
            }
        } header: {
            Text("Pop")
        } footer: {
            Text("Meta-based pops compare cases, not values. `.leaf` screens "
                 + "differ only by label, so popToFirst lands on the first of "
                 + "them; popToRoot is the one that always clears the stack.")
        }
    }
}
