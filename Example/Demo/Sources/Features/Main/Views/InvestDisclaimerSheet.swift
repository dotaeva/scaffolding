import SwiftUI
import Scaffolding

/// Presented by MainTabCoordinator.shouldSelect when the invest tab is
/// tapped before it's unlocked — the tab switch itself was vetoed.
struct InvestDisclaimerSheet: View {
    @Environment(MainTabCoordinator.self) private var tabCoordinator

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 36))
                .foregroundStyle(.yellow)
            Text("Investing involves risk")
                .font(.title3.weight(.semibold))
            Text("Capital is at risk. This is a demo — the numbers are made up.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("I understand") {
                tabCoordinator.acceptInvestDisclaimer()
            }
            .buttonStyle(.pill)
            Button("Not now") {
                tabCoordinator.dismissModal()
            }
        }
        .padding(24)
        .presentationBackground(.thinMaterial)
    }
}
