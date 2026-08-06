import SwiftUI

/// No controls on purpose: a view-only modal has no coordinator, so the
/// presenter's dismissModal() is the only programmatic way to close it.
struct ProcessingOverlay: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Ordering replacement…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .presentationBackground(.thinMaterial)
    }
}
