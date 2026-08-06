import Testing
import Scaffolding
import ScaffoldingTesting
@testable import Planets

@MainActor
@Suite("Tabs")
struct TabTests {

    @Test("shouldSelect vetoes the gated tab and shows the paywall")
    func gatedTabIsVetoed() {
        let tabs = AppCoordinator().activated()

        // The hook is an ordinary method — call it the way the tab bar does.
        let allowed = tabs.shouldSelect(tab: .search, isReselection: false)

        #expect(!allowed)
        #expect(tabs.isPresentingModal)
    }

    @Test("re-tapping the selected tab pops its flow to the root")
    func reselectionPopsToRoot() {
        let tabs = AppCoordinator().activated()
        let planets = tabs.selectFirstTab(.planets, expecting: PlanetsCoordinator.self)
        planets?.route(to: .detail(name: "Mars"))

        _ = tabs.shouldSelect(tab: .planets, isReselection: true)

        #expect(planets?.depth == 0)
    }

    @Test("each tab owns an independent stack")
    func stacksAreIndependent() {
        let tabs = AppCoordinator().activated()
        let planets = tabs.selectFirstTab(.planets, expecting: PlanetsCoordinator.self)
        let favorites = tabs.selectFirstTab(.favorites, expecting: FavoritesCoordinator.self)

        planets?.route(to: .detail(name: "Mars"))

        #expect(planets?.depth == 1)
        #expect(favorites?.depth == 0)
    }
}
