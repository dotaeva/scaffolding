import SwiftUI
import Scaffolding

/// Modal family: presenter-side sheet configuration, view-only modals,
/// dismissModal, and the async variants (presentAndWait, awaiting:).
@MainActor
@Observable
@Scaffoldable(codable: true)
final class CardsCoordinator: @MainActor GlassTabFlow {
    var stack = FlowStack<CardsCoordinator>(root: .cards)

    var frozen: Set<Card.ID> = []
    var limit: Decimal = 1_500
    var toast: String?

    // MARK: Routes

    func cards() -> some View { CardsScreen().tabScreenFade() }
    func cardDetail(card: Card) -> some View { CardDetailSheet(card: card) }
    func freezeConfirm(card: Card) -> some View { FreezeConfirmSheet(card: card) }
    func pinChange() -> some View { PinChangeScreen() }
    // View-only modal with no controls — only the presenter can close it.
    func processing() -> some View { ProcessingOverlay() }
    // Child coordinator whose whole job is returning a value.
    func limitPicker() -> any Coordinatable { LimitCoordinator() }

    // MARK: Modals

    /// The presenter decides the sheet chrome (detents here); the destination
    /// view stays ignorant and can be presented differently elsewhere.
    func openDetail(_ card: Card) {
        present(.cardDetail(card: card), as: .sheet(detents: [.medium, .large]), policy: .distinct)
    }

    /// interactiveDismissDisabled: the user must answer — swipe-down is off,
    /// programmatic dismissal still works. The sheet reads this back from
    /// @Environment(\.destination).modalConfiguration.
    func askFreeze(_ card: Card) {
        present(.freezeConfirm(card: card), as: .sheet(
            detents: [.medium],
            dragIndicator: .hidden,
            interactiveDismissDisabled: true
        ))
    }

    func resolveFreeze(_ card: Card, freeze: Bool) {
        if freeze { frozen.insert(card.id) } else { frozen.remove(card.id) }
        // Presenter-side close — same coordinator presented the sheet.
        dismissModal()
    }

    // MARK: Async variants

    /// present(awaiting:) suspends until the picker flow is dismissed and
    /// returns what it passed to dismissCoordinator(returning:); any other
    /// dismissal (swipe, plain dismissCoordinator) resumes with nil.
    func changeLimit() {
        Task {
            guard let picked = await present(.limitPicker, awaiting: Decimal.self) else { return }
            limit = picked
            toast = "Limit set to \(picked.formatted(.currency(code: "EUR")))"
        }
    }

    /// presentAndWait: no result, just "continue once it's gone".
    func changePin() {
        Task {
            await presentAndWait(.pinChange, as: .fullScreenCover)
            toast = "PIN updated"
        }
    }

    /// A modal the user can't interact with, closed by the presenter when
    /// the work finishes — dismissModal() is the only way to close a
    /// view-only modal programmatically.
    func orderReplacement() {
        guard !isPresentingModal else { return }
        present(.processing, as: .sheet(detents: [.medium], interactiveDismissDisabled: true))
        Task {
            try? await Task.sleep(for: .seconds(2))
            dismissModal()
            toast = "Replacement card ordered"
        }
    }
}

#Preview {
    CardsCoordinator().view
        .preferredColorScheme(.dark)
}
