import SwiftUI
import Scaffolding

/// One tab per flow coordinator. The native tab bar stays hidden; the
/// floating glass bar installed in `customize` is the only tab UI.
@MainActor
@Observable
@Scaffoldable(codable: true)
final class MainTabCoordinator: @MainActor TabCoordinatable {
    var tabItems = TabItems<MainTabCoordinator>(
        tabs: [.home, .cards, .invest, .profile],
        selectedIndex: 0,
        visibility: .hidden
    )

    /// Visual state of the glass bar (minimize, highlight slide).
    let barModel = GlassTabBarModel()

    /// Gate for the invest tab — see shouldSelect below.
    var investUnlocked = false

    // MARK: Routes

    // Custom tab bar ⇒ no label views: plain `any Coordinatable` returns
    // instead of `(any Coordinatable, some View)` tuples. The macro still
    // generates the cases; the tabs just have no native labels.
    func home() -> any Coordinatable { HomeCoordinator() }
    func cards() -> any Coordinatable { CardsCoordinator() }
    func invest() -> any Coordinatable { InvestCoordinator() }
    func profile() -> any Coordinatable { ProfileCoordinator() }

    // View-only tab (no coordinator) — added and removed at runtime by the
    // developer screen via appendTab/insertTab/removeFirstTab.
    func promo() -> some View { PromoScreen().tabScreenFade() }

    // Presented above the whole TabView when shouldSelect vetoes the
    // invest tab.
    func investDisclaimer() -> some View { InvestDisclaimerSheet() }

    // MARK: Glass bar wiring

    /// Chrome-side mirror of the tab destinations — derived from
    /// `tabItems.tabs`, so dynamic tab changes and badges can never drift
    /// from the actual configuration.
    var barItems: [GlassTabItem] {
        tabItems.tabs.compactMap { tab in
            guard let spec = (tab.meta as? Destinations.Meta)?.barSpec else { return nil }
            return GlassTabItem(
                id: tab.id,
                label: spec.label,
                systemImage: spec.systemImage,
                badge: tab.badge
            )
        }
    }

    /// Zero-based index of the selected tab, for syncing the custom chrome.
    var selectedIndex: Int {
        tabItems.tabs.firstIndex { $0.id == tabItems.selectedTab } ?? 0
    }

    /// The glass bar stands down whenever the native bar is shown — only
    /// one tab bar at a time (see the developer screen's toggle).
    var showsGlassBar: Bool {
        tabItems.tabBarVisibility == .hidden
    }

    /// Bar taps land here. `select(index:)` is programmatic and bypasses
    /// shouldSelect, so a custom bar has to consult the hook itself.
    func barTapped(_ index: Int) {
        guard tabItems.tabs.indices.contains(index),
              let meta = tabItems.tabs[index].meta as? Destinations.Meta else { return }

        let isReselection = index == selectedIndex
        guard shouldSelect(tab: meta, isReselection: isReselection), !isReselection else {
            // Vetoed or a re-tap: slide the highlight back to the applied
            // selection (no-op when it never left).
            barModel.slide(to: selectedIndex)
            return
        }
        select(index: index)
    }

    // MARK: Selection interception

    // Returns Bool ⇒ never macro-tracked. Fires for UI-driven selection
    // only; selectFirstTab / select(index:) / deep links bypass it.
    func shouldSelect(tab: Destinations.Meta, isReselection: Bool) -> Bool {
        if isReselection {
            // Re-tap of the current tab pops its flow to the root. The typed
            // trailing closure hands over the tab's child coordinator.
            switch tab {
            case .home: selectFirstTab(.home) { (c: HomeCoordinator) in c.popToRoot() }
            case .cards: selectFirstTab(.cards) { (c: CardsCoordinator) in c.popToRoot() }
            case .invest: selectFirstTab(.invest) { (c: InvestCoordinator) in c.popToRoot() }
            case .profile: selectFirstTab(.profile) { (c: ProfileCoordinator) in c.popToRoot() }
            default: break
            }
            return true // ignored for re-taps — there's no change to veto
        }
        if tab == .invest && !investUnlocked {
            // Keep the current tab and show the gate instead.
            present(.investDisclaimer, as: .sheet(detents: [.medium]))
            return false
        }
        return true
    }

    func acceptInvestDisclaimer() {
        investUnlocked = true
        dismissModal()
        selectFirstTab(.invest) // programmatic — won't re-enter shouldSelect
    }

    // MARK: Chrome

    @ScaffoldingIgnored
    func customize(_ view: AnyView) -> some View {
        view.modifier(GlassTabBarChrome(coordinator: self, model: barModel))
    }
}

/// Labels and icons for the glass bar. `nil` for routes that are never tabs.
extension MainTabCoordinator.Destinations.Meta {
    var barSpec: (label: String, systemImage: String)? {
        switch self {
        case .home: ("Home", "house.fill")
        case .cards: ("Cards", "creditcard.fill")
        case .invest: ("Invest", "chart.line.uptrend.xyaxis")
        case .profile: ("Profile", "person.crop.circle")
        case .promo: ("Promo", "gift.fill")
        case .investDisclaimer: nil
        }
    }
}
