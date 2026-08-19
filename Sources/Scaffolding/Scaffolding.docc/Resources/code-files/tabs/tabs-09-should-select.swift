import SwiftUI
import Scaffolding

@Scaffoldable @Observable
final class AppCoordinator: @MainActor TabCoordinatable {
    var tabItems = TabItems<AppCoordinator>(tabs: [.planets, .favorites, .search])

    var isSubscribed = false

    init() {
        setTabAccessibilityIdentifier("tab.planets", for: .planets)
        setTabAccessibilityIdentifier("tab.favorites", for: .favorites)
        setTabAccessibilityIdentifier("tab.search", for: .search)
    }

    func planets() -> (any Coordinatable, some View) {
        (PlanetsCoordinator(), Label("Planets", systemImage: "globe"))
    }

    func favorites() -> (any Coordinatable, some View) {
        (FavoritesCoordinator(), Label("Favorites", systemImage: "star"))
    }

    func search() -> (any Coordinatable, some View, TabRole) {
        (SearchCoordinator(), Label("Search", systemImage: "magnifyingglass"), .search)
    }

    func paywall() -> some View { PaywallSheet() }

    // Returns Bool ⇒ never tracked as a destination, so no
    // @ScaffoldingIgnored needed here.
    func shouldSelect(tab: Destinations.Meta, isReselection: Bool) -> Bool {
        if isReselection {
            // Re-tap of the selected tab pops its flow back to the root.
            if tab == .planets {
                selectFirstTab(.planets, expecting: PlanetsCoordinator.self)?.popToRoot()
            }
            return true   // ignored for re-taps — there is no change to veto
        }

        if tab == .search && !isSubscribed {
            present(.paywall, as: .sheet(detents: [.medium]))
            return false  // keep the current tab
        }

        return true
    }
}
