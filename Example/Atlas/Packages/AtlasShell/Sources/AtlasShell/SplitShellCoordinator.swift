import SwiftUI
import Scaffolding
import AtlasDomain
import AtlasDesign
import AtlasExplore
import AtlasSaved
import AtlasPlaces
import AtlasLab

public enum AtlasSection: String, CaseIterable, Identifiable { case discover = "Discover", saved = "Saved", lab = "Lab"; public var id: Self { self } }

@MainActor @Observable @Scaffoldable(codable: true)
public final class SplitShellCoordinator: SplitCoordinatable, AtlasSelectionDelegate {
    public var columns = SplitColumns<SplitShellCoordinator>(sidebar: .sidebar, content: .discover, detail: .empty)
    public let store: AtlasStore
    public var section: AtlasSection {
        switch contentDestination ?? detailDestination {
        case .saved: .saved
        case .lab: .lab
        default: .discover
        }
    }
    public var selectedPlaceID: String? {
        (hierarchySnapshot().first { $0.role == .column(.detail) }?.coordinator as? PlaceCoordinator)?.placeID
    }
    public var selectedJourneyID: UUID? {
        (hierarchySnapshot().first { $0.role == .column(.detail) }?.coordinator as? JourneyCoordinator)?.journeyID
    }
    public let context: AtlasSessionContext?
    private weak var session: (any AtlasSessionActions)?

    public init(store: AtlasStore, session: any AtlasSessionActions, context: AtlasSessionContext? = nil) { self.store = store; self.session = session; self.context = context }
    func sidebar() -> some View { AtlasSidebar() }
    func discover() -> any Coordinatable { ExploreCoordinator(store: store, selection: self, session: context) }
    func saved() -> any Coordinatable { SavedCoordinator(store: store, selection: self, session: context) }
    func lab() -> any Coordinatable { LabCoordinator(session: session, context: context) }
    func empty() -> some View { EmptyDetail() }
    func place(id: String) -> any Coordinatable { PlaceCoordinator(placeID: id, store: store, session: context) }

    func journey(id: UUID) -> any Coordinatable {
        JourneyCoordinator(journeyID: id, store: store, selection: self, session: context)
    }

    public func selectSection(_ section: AtlasSection) {
        guard self.section != section else { return }
        if section == .lab {
            removeContent()
            setDetail(.lab)
            setPreferredCompactColumn(.detail)
            return
        }
        switch section {
        case .discover: setContent(.discover, policy: .distinct)
        case .saved: setContent(.saved, policy: .distinct)
        case .lab: break
        }
        setDetail(.empty, policy: .distinct)
        setPreferredCompactColumn(.content)
    }

    public func openJourney(_ id: UUID) {
        guard selectedJourneyID != id, store.plan(id) != nil else { return }
        setDetail(.journey(id: id))
        setPreferredCompactColumn(.detail)
    }
    public func clearJourney(_ id: UUID) {
        guard selectedJourneyID == id else { return }
        setDetail(.empty)
        setPreferredCompactColumn(.content)
    }

    public func openPlace(_ id: String) {
        guard selectedPlaceID != id, PlaceCatalog.place(id) != nil else { return }
        setDetail(.place(id: id))
        setPreferredCompactColumn(.detail)
    }
}

private struct EmptyDetail: View {
    var body: some View {
        AtlasForm {
            ContentUnavailableView("Select a place or journey", systemImage: "map", description: Text("Choose an item in Discover or Saved to see its details."))
        }
    }
}
