import Foundation
import Testing
import Scaffolding
import ScaffoldingTesting
import AtlasAppFeature
import AtlasDomain
import AtlasShell
import AtlasExplore
import AtlasPlaces
import AtlasSaved
import AtlasPlanner
import AtlasLab

@MainActor
@Suite("Atlas collection and UX regressions")
struct AtlasCollectionTests {
    @Test("Saving is durable without a navigation checkpoint")
    func persistence() throws {
        let folder = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = folder.appending(path: "collection.json")
        let store = AtlasStore(storageURL: url)
        store.markStarted()
        store.toggleSaved("lofoten")
        let plan = TripPlan(placeID: "lofoten", days: 5, pace: .balanced)
        store.add(plan)
        let reopened = AtlasStore(storageURL: url)
        #expect(reopened.snapshot == store.snapshot)
        let app = AtlasCoordinator(store: reopened).activated()
        app.bootstrap(checkpoint: nil)
        #expect(app.isRoot(.workspace))
        #expect(!app.hasCheckpoint)
        reopened.remove(plan.id)
        #expect(AtlasStore(storageURL: url).plans.isEmpty)
    }

    @Test("An unreadable collection is preserved and reported")
    func unreadableCollection() throws {
        let url = FileManager.default.temporaryDirectory.appending(path: "atlas-\(UUID()).json")
        defer { try? FileManager.default.removeItem(at: url) }
        let original = Data("not JSON".utf8)
        try original.write(to: url)
        let store = AtlasStore(storageURL: url)
        store.toggleSaved("lofoten")
        #expect(store.persistenceError != nil)
        #expect(try Data(contentsOf: url) == original)
    }

    @Test("Windows share content but keep separate navigation and feedback")
    func windows() throws {
        let store = AtlasStore()
        let first = AtlasCoordinator(store: store).activated()
        let second = AtlasCoordinator(store: store).activated()
        first.openExampleLink()
        second.startExploring()
        first.session.show("A message in the first window")
        store.add(TripPlan(placeID: "kyoto", days: 4, pace: .unhurried))
        #expect(second.store.plans.count == 1)
        #expect(second.session.message == nil)
        #expect(first.descendant(ofType: PlaceCoordinator.self) != nil)
        #expect(second.descendant(ofType: PlaceCoordinator.self) == nil)
    }

    @Test("Journey actions preserve the Discover flow and support edit, remove, and undo", arguments: AtlasLayout.allCases)
    func journey(layout: AtlasLayout) async throws {
        let app = AtlasCoordinator(layout: layout).activated()
        app.openExampleLink()
        let originalPlace = try #require(app.descendant(ofType: PlaceCoordinator.self))
        let plan = TripPlan(placeID: "dolomites", days: 5, pace: .balanced)
        app.store.add(plan)
        app.session.show("Saved", action: .journey(plan.id))
        app.session.performMessageAction()
        app.activated()
        let journey = try #require(app.descendant(ofType: JourneyCoordinator.self))
        #expect(journey.plan == plan)
        if layout == .tabs {
            #expect(app.descendant(ofType: PlaceCoordinator.self) === originalPlace)
        }
        journey.edit()
        await waitUntil { journey.isPresentingModal }
        journey.activated()
        let planner = try #require(journey.descendant(ofType: PlannerCoordinator.self))
        #expect(planner.days == 5 && planner.pace == .balanced && planner.isEditing)
        planner.days = 7
        planner.finish()
        await waitUntil { !journey.isEditing }
        #expect(app.store.plans.count == 1)
        #expect(app.store.plan(plan.id)?.days == 7)
        journey.remove()
        #expect(app.store.plans.isEmpty)
        #expect(app.descendant(ofType: JourneyCoordinator.self) == nil)
        app.session.performMessageAction()
        #expect(app.store.plan(plan.id)?.days == 7)
    }

    @Test("The split Lab uses the detail area and restores its structure")
    func splitLab() throws {
        let app = AtlasCoordinator(layout: .split).activated()
        app.startExploring()
        app.activated()
        let split = try #require(app.descendant(ofType: SplitShellCoordinator.self))
        split.selectSection(.lab)
        #expect(split.contentDestination == nil)
        #expect(split.detailDestination == .lab)
        #expect(split.section == .lab)
        app.saveCheckpoint()
        app.switchLayout(.tabs)
        app.restoreCheckpoint()
        app.activated()
        let restored = try #require(app.descendant(ofType: SplitShellCoordinator.self))
        #expect(restored.contentDestination == nil)
        #expect(restored.detailDestination == .lab)
        restored.selectSection(.discover)
        #expect(restored.contentDestination == .discover)
        #expect(restored.detailDestination == .empty)
    }

    @Test("A journey checkpoint resolves the latest saved plan", arguments: AtlasLayout.allCases)
    func journeyCheckpoint(layout: AtlasLayout) throws {
        let app = AtlasCoordinator(layout: layout).activated()
        app.startExploring()
        app.activated()
        let plan = TripPlan(placeID: "kyoto", days: 5, pace: .unhurried)
        app.store.add(plan)
        app.openJourney(plan.id)
        app.activated()
        app.saveCheckpoint()
        let edited = TripPlan(id: plan.id, placeID: plan.placeID, days: 7, pace: .balanced)
        app.store.update(edited)
        app.store.add(TripPlan(placeID: "lofoten", days: 2, pace: .adventurous))
        app.switchLayout(layout == .tabs ? .split : .tabs)
        app.restoreCheckpoint()
        app.activated()
        #expect(app.descendant(ofType: JourneyCoordinator.self)?.plan == edited)
        #expect(app.store.plans.count == 2)
    }

    @Test("Legacy navigation checkpoints cannot overwrite a newer collection")
    func legacyCheckpoint() throws {
        let app = AtlasCoordinator().activated()
        app.openExampleLink()
        app.saveCheckpoint()
        let data = try #require(app.checkpointData)
        var legacy = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        legacy["version"] = 1
        legacy.removeValue(forKey: "createdAt")
        legacy["content"] = ["savedIDs": ["kyoto"], "plans": []]
        let store = AtlasStore()
        let plan = TripPlan(placeID: "lofoten", days: 5, pace: .balanced)
        store.add(plan)
        let restored = AtlasCoordinator(store: store).activated()
        restored.bootstrap(checkpoint: try JSONSerialization.data(withJSONObject: legacy))
        restored.activated()
        #expect(restored.store.plan(plan.id) == plan)
        #expect(restored.descendant(ofType: PlaceCoordinator.self)?.placeID == "lofoten")
    }
}
