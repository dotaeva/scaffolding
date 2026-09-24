import SwiftUI
import Scaffolding

/// A view-only modal: no coordinator inside it, and no navigation
/// container either, so it lays out its own header and close control.
struct PlaygroundModalView: View {
    // The presenting coordinator is injected here too — every *ancestor*
    // is, from any depth — which is what lets a view-only modal offer the
    // presenter-side dismissals. Optional, because this same view is also
    // rendered in previews outside any flow.
    @Environment(PlaygroundCoordinator.self) private var presenter: PlaygroundCoordinator?
    @Environment(\.destination) private var destination
    @Environment(\.dismiss) private var dismiss

    let title: String
    var isLocked = false

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

            if let presenter {
                VStack(spacing: 6) {
                    // Presenter-side dismissal, driven from the modal
                    // because that is the only thing on screen right now.
                    Button("presenter.dismissModal()") { presenter.dismissModal() }
                    Button("presenter.dismissAllModals()") { presenter.dismissAllModals() }
                }
                .font(.footnote)
                .buttonStyle(.borderless)
            }
        }
        .padding(28)
        .frame(maxWidth: 420)
        .sheetSizing(minHeight: 300, idealHeight: 340)
    }
}
