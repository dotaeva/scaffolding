import SwiftUI
import Scaffolding

/// The presenter disabled interactive dismissal — the sheet reads that back
/// from the destination environment instead of hardcoding it.
struct FreezeConfirmSheet: View {
    @Environment(CardsCoordinator.self) private var coordinator
    @Environment(\.destination) private var destination

    let card: Card

    private var isFrozen: Bool {
        coordinator.frozen.contains(card.id)
    }

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "snowflake")
                .font(.system(size: 40))
                .foregroundStyle(.cyan)
            Text(isFrozen ? "Unfreeze card •••• \(card.suffix)?" : "Freeze card •••• \(card.suffix)?")
                .font(.title3.weight(.semibold))
            Button(isFrozen ? "Unfreeze" : "Freeze") {
                coordinator.resolveFreeze(card, freeze: !isFrozen)
            }
            .buttonStyle(.pill(fill: .red))
            Button("Cancel") {
                // dismissModal() from the sheet's own coordinator — the
                // presenter and this view share it.
                coordinator.dismissModal()
            }
            if destination.modalConfiguration?.interactiveDismissDisabled == true {
                Text("Swipe-down is disabled — set by the presenter via .sheet(interactiveDismissDisabled:).")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(24)
        .presentationBackground(.thinMaterial)
    }
}
