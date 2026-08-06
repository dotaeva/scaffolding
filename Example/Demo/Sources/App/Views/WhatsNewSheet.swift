import SwiftUI

/// Presented by the AppCoordinator above the current root.
struct WhatsNewSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("What's new")
                    .font(.title2.weight(.semibold))
                Spacer()
                Button("Close") { dismiss() }
            }
            Label("Glass tab bar with scrubbing", systemImage: "sparkles")
            Label("Orders and spending limits", systemImage: "chart.line.uptrend.xyaxis")
            Label("Deep links: scaffolding-demo://holding/NVDA", systemImage: "link")
            Spacer()
        }
        .padding(24)
        // Modals presented by the root render outside customize(_:)'s wrapper,
        // so they don't inherit its app-wide .tint(.white).
        .tint(.white)
        .presentationBackground(.thinMaterial)
    }
}
