import Testing
import Scaffolding
import ScaffoldingTesting
@testable import Planets

@MainActor
@Suite("Modals")
struct ModalTests {

    @Test("a presented flow pushes inside itself, not into the presenter")
    func presentedFlowOwnsItsStack() {
        let favorites = FavoritesCoordinator().activated()

        // The test performs the navigation, so `expecting:` hands back the
        // resolved child, typed.
        let picker = favorites.present(.picker, expecting: PlanetPickerCoordinator.self)
        picker?.openCustom()

        #expect(picker?.depth == 1)            // pushed inside the sheet
        #expect(favorites.depth == 0)          // presenter's stack untouched
        #expect(picker?.routeType == .sheet)   // how the child was presented
        #expect(picker?.ancestor(ofType: FavoritesCoordinator.self) === favorites)
    }

    @Test("dismissModal is a no-op when nothing is presented")
    func dismissModalIsSafe() {
        let favorites = FavoritesCoordinator().activated()
        favorites.route(to: .detail(name: "Mars"))

        favorites.dismissModal()

        #expect(favorites.depth == 1)          // pop() would have removed it
    }
}
