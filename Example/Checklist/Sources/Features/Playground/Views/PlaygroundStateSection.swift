import SwiftUI
import Scaffolding

/// Everything the orientation API can tell you about this flow, live.
struct PlaygroundStateSection: View {
    @Environment(PlaygroundCoordinator.self) private var coordinator
    @Environment(\.destination) private var destination

    private let columns = [GridItem(.adaptive(minimum: 148), spacing: 10)]

    var body: some View {
        Section("State") {
            LazyVGrid(columns: columns, spacing: 10) {
                tile("depth", "\(coordinator.depth)")
                tile("topDestination", caseLabel(coordinator.topDestination))
                tile("count(.playground)", "\(coordinator.count(of: .playground))")
                tile("count(.leaf)", "\(coordinator.count(of: .leaf))")
                tile("isInStack(.child)", String(coordinator.isInStack(.child)))
                tile("isPresentingModal", String(coordinator.isPresentingModal))
                tile("flow.routeType", caseLabel(coordinator.routeType))
                tile("screen.routeType", caseLabel(destination.routeType))
                tile("onDismiss count", "\(coordinator.dismissals)")
                tile("last result", coordinator.lastResult ?? "—")
            }
            .padding(.vertical, 4)
            Button("Reset readouts") { coordinator.resetReadouts() }
        }
    }

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
