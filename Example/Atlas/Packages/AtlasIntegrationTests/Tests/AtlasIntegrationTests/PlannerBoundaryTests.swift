import Testing
import Scaffolding
import ScaffoldingTesting
import AtlasAppFeature
import AtlasDomain
import AtlasPlaces
import AtlasPlanner

@MainActor
@Suite("Planner result boundary")
struct PlannerBoundaryTests {
    @Test("A plan returns across modules exactly once", arguments: [false, true])
    func result(fullScreen: Bool) async throws {
        let store = AtlasStore()
        let place = PlaceCoordinator(placeID: "dolomites", store: store).activated()
        place.plan(fullScreen: fullScreen)
        place.plan(fullScreen: fullScreen)
        await waitUntil { place.isPresentingModal }
        place.activated()
        let planner = try #require(place.descendant(ofType: PlannerCoordinator.self))
        #expect(place.hierarchySnapshot().filter { $0.role.isModal }.count == 1)
        #expect(planner.routeType == (fullScreen ? .fullScreenCover : .sheet))
        planner.days = 5
        planner.pace = .adventurous
        planner.continuePlanning()
        #expect(planner.topDestination == .review)
        planner.finish()
        await waitUntil { !place.isPlanning }
        #expect(!place.isPresentingModal)
        #expect(store.plans.count == 1)
        #expect(store.plans.first?.placeID == "dolomites")
        #expect(store.plans.first?.days == 5)
    }

    @Test("Closing a planner produces no journey and allows a new attempt")
    func cancellation() async throws {
        let place = PlaceCoordinator(placeID: "kyoto", store: AtlasStore()).activated()
        place.plan()
        await waitUntil { place.isPresentingModal }
        place.dismissModal()
        await waitUntil { !place.isPlanning }
        #expect(place.store.plans.isEmpty)
        place.plan()
        await waitUntil { place.isPresentingModal }
        place.dismissModal()
        await waitUntil { !place.isPlanning }
    }

    @Test("An unfinished result flow cannot become a restorable checkpoint")
    func transientCheckpoint() async throws {
        let app = AtlasCoordinator().activated()
        app.openExampleLink()
        app.activated()
        let place = try #require(app.descendant(ofType: PlaceCoordinator.self))
        place.plan()
        await waitUntil { place.isPresentingModal }
        app.saveCheckpoint()
        #expect(!app.hasCheckpoint)
        place.dismissModal()
        await waitUntil { !place.isPlanning }
        app.saveCheckpoint()
        #expect(app.hasCheckpoint)
    }
}
