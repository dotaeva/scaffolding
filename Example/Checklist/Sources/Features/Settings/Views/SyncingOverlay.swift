import SwiftUI

/// A view-only modal with no controls at all: interactive dismissal is
/// disabled by the presenter and there is no coordinator inside to call
/// `dismissCoordinator()`. The presenting flow closes it with
/// `dismissModal()` when the work finishes.
struct SyncingOverlay: View {
    var body: some View {
        VStack(spacing: 14) {
            ProgressView()
                .controlSize(.large)
            Text("Syncing…")
                .font(.headline)
            Text("No buttons on purpose — the presenter dismisses this one.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(maxWidth: 380)
        .sheetSizing(minHeight: 220, idealHeight: 260)
    }
}
