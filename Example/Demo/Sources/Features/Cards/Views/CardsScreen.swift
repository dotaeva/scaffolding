import SwiftUI
import Scaffolding

struct CardsScreen: View {
    @Environment(CardsCoordinator.self) private var coordinator

    var body: some View {
        @Bindable var coordinator = coordinator
        ScrollView {
            LazyVStack(spacing: 20) {
                ForEach(Card.samples) { card in
                    Button {
                        coordinator.openDetail(card)
                    } label: {
                        PaymentCard(card: card, frozen: coordinator.frozen.contains(card.id))
                    }
                    .buttonStyle(.plain)
                }

                VStack(spacing: 4) {
                    row("Freeze card", "snowflake") {
                        coordinator.askFreeze(Card.samples[0])
                    }
                    row("Spending limit", "gauge.with.needle",
                        trailing: coordinator.limit.formatted(.currency(code: "EUR"))) {
                        coordinator.changeLimit()
                    }
                    row("Change PIN", "lock.shield") {
                        coordinator.changePin()
                    }
                    row("Replace card", "arrow.triangle.2.circlepath") {
                        coordinator.orderReplacement()
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
        }
        .background(ScreenBackground())
        .statusBarScrim()
        .toolbar(.hidden, for: .navigationBar)
        .toast($coordinator.toast)
    }

    private func row(
        _ title: String,
        _ systemImage: String,
        trailing: String? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            IconRow(title: title, systemImage: systemImage, trailing: trailing)
        }
        .buttonStyle(.plain)
    }
}
