import SwiftUI
import Scaffolding
import AtlasDomain
import AtlasExplore
import AtlasSaved
import AtlasLab

@MainActor @Observable @Scaffoldable(codable: true)
public final class TabShellCoordinator: TabCoordinatable {
    public var tabItems = TabItems<TabShellCoordinator>(tabs: [.discover, .saved, .lab])
    public let store: AtlasStore
    public let context: AtlasSessionContext?
    private weak var session: (any AtlasSessionActions)?

    public init(store: AtlasStore, session: any AtlasSessionActions, context: AtlasSessionContext? = nil) {
        self.store = store; self.session = session; self.context = context
        setTabAccessibilityIdentifier("tab.discover", for: .discover)
        setTabAccessibilityIdentifier("tab.saved", for: .saved)
        setTabAccessibilityIdentifier("tab.lab", for: .lab)
        updateBadge()
    }
    func discover() -> (any Coordinatable, some View) { (ExploreCoordinator(store: store, session: context), Label("Discover", systemImage: "globe.europe.africa")) }
    func saved() -> (any Coordinatable, some View) { (SavedCoordinator(store: store, session: context), Label("Saved", systemImage: "bookmark")) }
    func lab() -> (any Coordinatable, some View) { (LabCoordinator(session: session, context: context), Label("Lab", systemImage: "square.stack.3d.up")) }

    public func updateBadge() {
        let count = store.savedIDs.count + store.plans.count
        setBadge(count == 0 ? nil : "\(count)", for: .saved)
    }

    public func openJourney(_ id: UUID) {
        selectFirstTab(.saved) { (saved: SavedCoordinator) in saved.showJourney(id) }
    }

    public func shouldSelect(tab: Destinations.Meta, isReselection: Bool) -> Bool {
        guard isReselection else { return true }
        switch tab {
        case .discover: selectFirstTab(.discover) { (flow: ExploreCoordinator) in flow.popToRoot() }
        case .saved: selectFirstTab(.saved) { (flow: SavedCoordinator) in flow.popToRoot() }
        case .lab: selectFirstTab(.lab) { (flow: LabCoordinator) in flow.popToRoot() }
        }
        return true
    }

}

extension TabShellCoordinator {
    public func customize(_ view: AnyView) -> some View {
        view.onChange(of: store.savedIDs) { _, _ in self.updateBadge() }
            .onChange(of: store.plans) { _, _ in self.updateBadge() }
    }
}
