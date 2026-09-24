import SwiftUI
import Scaffolding
import AtlasDomain
import AtlasDesign
import AtlasPlanner

@MainActor @Observable @Scaffoldable(codable: true)
public final class PlaceCoordinator: FlowCoordinatable {
    public var stack: FlowStack<PlaceCoordinator>
    public let placeID: String
    public let store: AtlasStore
    public let session: AtlasSessionContext?
    public private(set) var isPlanning = false

    public init(placeID: String, store: AtlasStore, session: AtlasSessionContext? = nil) {
        self.placeID = placeID
        self.store = store
        self.session = session
        self.stack = FlowStack(root: .overview)
    }

    func overview() -> some View { PlaceScreen() }
    func highlights() -> some View { HighlightsScreen() }
    func planner() -> any Coordinatable {
        PlannerCoordinator(place: PlaceCatalog.place(placeID) ?? PlaceCatalog.all[0])
    }

    public func showHighlights() { route(to: .highlights, policy: .distinct) }

    public func plan(fullScreen: Bool = false) {
        guard !isPlanning, !isPresentingModal, PlaceCatalog.place(placeID) != nil else { return }
        isPlanning = true
        Task { @MainActor [weak self] in
            guard let self else { return }
            defer { isPlanning = false }
            let result = await present(.planner, as: fullScreen ? .fullScreenCover : .sheet, awaiting: TripPlan.self)
            if let result {
                store.add(result)
                session?.show("Journey saved to your collection.", action: .journey(result.id))
            }
        }
    }
}
