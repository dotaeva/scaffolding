import Foundation
import Scaffolding
import AtlasDomain
import AtlasShell
import AtlasExplore
import AtlasPlaces
import AtlasSaved

extension AtlasCoordinator {
    public func openExampleLink() {
        open(.place("lofoten", highlights: true))
    }

    @discardableResult
    public func handle(_ url: URL) -> Bool {
        guard let link = AtlasLink(url: url) else {
            session.show("This link does not point to a place in the collection.")
            return false
        }
        open(link)
        return true
    }

    public func openJourney(_ id: UUID) {
        guard store.plan(id) != nil else { session.show("This journey is no longer in your collection."); return }
        session.dismissMessage()
        switch layout {
        case .tabs:
            withWorkspace { (tabs: TabShellCoordinator) in tabs.openJourney(id) }
        case .split:
            withWorkspace { (split: SplitShellCoordinator) in
                split.selectSection(.saved)
                split.openJourney(id)
            }
        }
    }

    /// Walks the tree with typed handles, including from the welcome screen.
    private func open(_ link: AtlasLink) {
        store.markStarted()
        session.dismissMessage()
        switch link {
        case let .place(id, highlights):
            switch layout {
            case .tabs:
                withWorkspace { (tabs: TabShellCoordinator) in
                    tabs.selectFirstTab(.discover) { (explore: ExploreCoordinator) in
                        explore.popToRoot()
                        explore.route(to: .place(id: id)) { (place: PlaceCoordinator) in
                            if highlights { place.showHighlights() }
                        }
                    }
                }
            case .split:
                withWorkspace { (split: SplitShellCoordinator) in
                    split.selectSection(.discover)
                    split.setDetail(.place(id: id)) { (place: PlaceCoordinator) in
                        if highlights { place.showHighlights() }
                    }
                    split.setPreferredCompactColumn(.detail)
                }
            }
        }
    }

    /// Resolve the current shell for this action; only replace the root when
    /// entering from Welcome. Replacing a split view during window startup
    /// also replaces the native toolbar host while it is being installed.
    private func withWorkspace<T: Coordinatable>(_ action: @escaping @MainActor (T) -> Void) {
        if let workspace = hierarchySnapshot().first(where: { $0.role == .root })?.coordinator as? T {
            action(workspace)
        } else {
            setRoot(.workspace(layout: layout), action)
        }
    }
}
