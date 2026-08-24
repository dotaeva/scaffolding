import SwiftUI
import Scaffolding

/// Every push and pop variant, live against the flow that owns this
/// screen. Push it repeatedly to build a stack, then watch the readouts
/// while the pop family takes it apart.
///
/// Pushed only — never presented. The readouts sit in an adaptive grid, so
/// the screen lays itself out for an iPhone column, an iPad sheet, or a
/// wide Mac window instead of needing a size imposed from outside.
struct PlaygroundView: View {
    @Environment(SettingsCoordinator.self) private var coordinator

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 10)]

    var body: some View {
        List {
            Section("State") {
                LazyVGrid(columns: columns, spacing: 10) {
                    tile("depth", "\(coordinator.depth)")
                    tile("topDestination", caseLabel(coordinator.topDestination))
                    tile("count(of: .playground)", "\(coordinator.count(of: .playground))")
                    tile("isInStack(.about)", String(coordinator.isInStack(.about)))
                }
                .padding(.vertical, 4)
            }

            Section("Push") {
                Button("route(to: .playground)") { coordinator.pushAnotherPlayground() }
                Button("replaceLast(with: .playground)") {
                    // Swaps the top screen, so back skips the one replaced.
                    coordinator.replaceLast(with: .playground)
                }
            }

            Section("Pop") {
                Button("pop()") { coordinator.pop() }
                if coordinator.depth >= 2 {
                    Button("pop(2)") { coordinator.pop(2) }
                }
                Button("popToRoot()") { coordinator.popToRoot() }
                if coordinator.count(of: .playground) >= 2 {
                    Button("popToFirst(.playground)") { coordinator.popToFirst(.playground) }
                    Button("popToLast(.playground)") { coordinator.popToLast(.playground) }
                }
            }
        }
        .navigationTitle("Playground")
    }

    /// A readout that scales its value down rather than truncating it or
    /// forcing the row taller.
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
        .background(.raisedBackground, in: .rect(cornerRadius: 8))
    }
}
