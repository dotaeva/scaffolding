import SwiftUI
import Scaffolding

/// View-only sheet. Presented with detents [.medium, .large] — chosen by
/// the presenter, not here.
struct CardDetailSheet: View {
    @Environment(CardsCoordinator.self) private var coordinator

    let card: Card

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Card details")
                    .font(.headline)
                Spacer()
                // Renders "Close" because \.destination.routeType is .sheet.
                AdaptiveDismissButton()
            }
            PaymentCard(card: card, frozen: coordinator.frozen.contains(card.id))
            LabeledContent("Number", value: "•••• •••• •••• \(card.suffix)")
            LabeledContent("Spending limit", value: coordinator.limit.formatted(.currency(code: "EUR")))
            Spacer()
        }
        .padding(20)
        .presentationBackground(.thinMaterial)
    }
}
