import Testing
import Foundation
import Scaffolding
import ScaffoldingTesting
@testable import Planets

@MainActor
@Suite("Awaited results")
struct AwaitedResultTests {

    @Test("the picker's choice arrives back at the presenter")
    func resultDelivered() async {
        let favorites = FavoritesCoordinator().activated()

        // addPlanet() awaits its own presentation, so drive it from a task.
        let adding = Task { await favorites.addPlanet() }
        await waitUntil { favorites.isPresentingModal }

        // present(_:awaiting:) hands back no coordinator — find the child in
        // the tree instead. It is never materialised by looking.
        favorites.descendant(ofType: PlanetPickerCoordinator.self)?.pick("Mars")
        await adding.value

        #expect(favorites.favorites == ["Mars"])
        #expect(!favorites.isPresentingModal)
    }

    @Test("backing out resumes with nil")
    func cancellationYieldsNil() async {
        let favorites = FavoritesCoordinator().activated()

        let picking = Task { await favorites.present(.picker, awaiting: String.self) }
        await waitUntil { favorites.isPresentingModal }

        favorites.dismissModal()               // stands in for a swipe-down

        #expect(await picking.value == nil)
        #expect(favorites.favorites.isEmpty)
    }
}
