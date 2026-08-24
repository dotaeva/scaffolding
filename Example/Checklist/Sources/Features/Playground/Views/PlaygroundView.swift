import SwiftUI
import Scaffolding

/// Every push and pop variant, live against the flow that owns this screen.
/// Push it a few times to build a stack, then watch the readouts while the
/// pop family takes it apart.
struct PlaygroundView: View {
    @Environment(PlaygroundCoordinator.self) private var coordinator

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 10)]

    var body: some View {
        List {
            Section("State") {
                LazyVGrid(columns: columns, spacing: 10) {
                    tile("depth", "\(coordinator.depth)")
                    tile("topDestination", caseLabel(coordinator.topDestination))
                    tile("count(of: .playground)", "\(coordinator.count(of: .playground))")
                    tile("isPresentingModal", String(coordinator.isPresentingModal))
                }
                .padding(.vertical, 4)
            }

            Section("Push") {
                Button("route(to: .playground)") { coordinator.push() }
                Button("replaceLast(with: .playground)") {
                    // Swaps the top screen, so back skips the one replaced.
                    coordinator.replaceTop()
                }
            }

            Section {
                Button("pop()") { coordinator.pop() }
                if coordinator.depth >= 2 {
                    Button("pop(2)") { coordinator.pop(2) }
                }
                Button("popToRoot()") { coordinator.popToRoot() }
                if coordinator.count(of: .playground) >= 2 {
                    Button("popToFirst(.playground)") { coordinator.popToFirst(.playground) }
                }
            } header: {
                Text("Pop")
            } footer: {
                Text("Every screen here is the same `.playground` case, and "
                     + "meta-based pops compare cases — so popToFirst matches "
                     + "the root and behaves like popToRoot. On a stack of "
                     + "mixed cases it stops in the middle.")
            }
        }
        .navigationTitle("Playground")
    }

    /// A readout that scales its value down rather than truncating it.
    private func tile(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.callout.monospaced())
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.groupedBackground, in: .rect(cornerRadius: 8))
    }
}
