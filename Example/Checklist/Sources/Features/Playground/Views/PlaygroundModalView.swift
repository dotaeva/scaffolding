import SwiftUI
import Scaffolding

/// A view-only modal: no coordinator inside it, and no navigation
/// container either, so it lays out its own header and close control.
struct PlaygroundModalView: View {
    @Environment(\.destination) private var destination
    @Environment(\.dismiss) private var dismiss

    let title: String

    private var isLocked: Bool {
        destination.modalConfiguration?.interactiveDismissDisabled == true
    }

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: isLocked ? "lock.fill" : "rectangle.portrait.on.rectangle.portrait")
                .font(.system(size: 34))
                .foregroundStyle(.tint)
            Text(title)
                .font(.title3.bold())
            VStack(spacing: 4) {
                Text("routeType: \(caseLabel(destination.routeType))")
                Text("presentationType: \(caseLabel(destination.presentationType))")
                if let detents = destination.modalConfiguration?.detents, !detents.isEmpty {
                    Text("detents: \(detents.count)")
                }
            }
            .font(.caption.monospaced())
            .foregroundStyle(.secondary)
            if isLocked {
                Text("Swipe-down is disabled — only the presenter can close "
                     + "this, with dismissModal().")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            } else {
                Button("Close") { dismiss() }
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(28)
        .frame(maxWidth: 420)
        .sheetSizing(minHeight: 300, idealHeight: 340)
    }
}
