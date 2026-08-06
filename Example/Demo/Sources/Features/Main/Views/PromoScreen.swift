import SwiftUI

/// View-only tab: no coordinator, no pushes — appended/removed at runtime
/// from the developer screen.
struct PromoScreen: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "gift.fill")
                .font(.system(size: 44))
                .foregroundStyle(.pink)
            Text("Invite a friend")
                .font(.title3.weight(.semibold))
            Text("This tab was added dynamically — it's a plain view, not a coordinator.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ScreenBackground())
    }
}

#Preview {
    PromoScreen()
        .preferredColorScheme(.dark)
}
