import SwiftUI

/// View-only modal with no controls at all: interactive dismissal is
/// disabled by the presenter and there is no coordinator inside to call
/// dismissCoordinator() — the presenting SettingsCoordinator closes it
/// with dismissModal() when the fake refresh finishes.
struct RefreshOverlay: View {
    var body: some View {
        VStack(spacing: 14) {
            ProgressView()
                .controlSize(.large)
            Text("Updating forecasts…")
                .font(.headline)
            Text("The presenter dismisses this when the work completes.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(32)
        .presentationBackground(.thinMaterial)
    }
}
