import SwiftUI
import Scaffolding

/// Read-only stack introspection, straight off the (observable) coordinator.
struct StackInspector: View {
    @Environment(HomeCoordinator.self) private var coordinator

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionTitle("Stack queries")
            row("depth", "\(coordinator.depth)")
            row("topDestination", String(describing: coordinator.topDestination))
            row("isInStack(.transaction)", "\(coordinator.isInStack(.transaction))")
            row("count(of: .transaction)", "\(coordinator.count(of: .transaction))")
            row("isPresentingModal", "\(coordinator.isPresentingModal)")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.white.opacity(0.05), in: .rect(cornerRadius: 12))
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
        }
        .font(.caption.monospaced())
    }
}
