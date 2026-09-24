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
import AtlasWelcome

@MainActor
@Suite("Atlas module integration")
struct AtlasNavigationTests {
    @Test("Welcome hands ownership to the tab shell")
    func welcome() throws {
        let app = AtlasCoordinator().activated()
        let welcome = try #require(app.descendant(ofType: WelcomeCoordinator.self))
        welcome.begin()
        app.activated()
        #expect(app.isRoot(.workspace))
        #expect(app.descendant(ofType: WelcomeCoordinator.self) == nil)
        #expect(app.descendant(ofType: TabShellCoordinator.self) != nil)
    }

    @Test("Cold links reach another module in either shell", arguments: AtlasLayout.allCases)
    func deepLink(layout: AtlasLayout) throws {
        let app = AtlasCoordinator(layout: layout).activated()
        #expect(app.handle(URL(string: "atlas://place/lofoten/highlights")!))
        app.activated()
        let place = try #require(app.descendant(ofType: PlaceCoordinator.self))
        #expect(place.placeID == "lofoten")
        #expect(place.topDestination == .highlights)
        #expect(place.depth == 1)
        #expect(app.descendant(ofType: WelcomeCoordinator.self) == nil)
    }

    @Test("Launch links reuse the workspace installed by scene bootstrap", arguments: AtlasLayout.allCases)
    func launchLinkPreservesWorkspace(layout: AtlasLayout) throws {
        let store = AtlasStore()
        store.markStarted()
        let app = AtlasCoordinator(layout: layout, store: store).activated()
        app.bootstrap(checkpoint: nil)
        let workspace = try #require(app.hierarchySnapshot().first?.coordinator)

        for url in ["atlas://place/lofoten/highlights", "atlas://place/lofoten/highlights", "atlas://place/kyoto"] {
            #expect(app.handle(URL(string: url)!))
            app.activated()
            #expect(app.hierarchySnapshot().first?.coordinator === workspace)
            let place = try #require(app.descendant(ofType: PlaceCoordinator.self))
            #expect(place.placeID == (url.hasSuffix("kyoto") ? "kyoto" : "lofoten"))
            #expect(place.depth == (url.hasSuffix("highlights") ? 1 : 0))
        }
    }

    @Test("Warm links preserve other tab histories and replace the Discover path")
    func warmTabLink() throws {
        let app = AtlasCoordinator().activated()
        app.startExploring()
        let tabs = try #require(app.descendant(ofType: TabShellCoordinator.self))
        let saved = try #require(tabs.selectFirstTab(.saved, expecting: SavedCoordinator.self))
        saved.choose("kyoto")
        let savedPlace = try #require(saved.descendant(ofType: PlaceCoordinator.self))

        app.openExampleLink()
        app.openExampleLink()

        #expect(app.descendant(ofType: TabShellCoordinator.self) === tabs)
        #expect(saved.descendant(ofType: PlaceCoordinator.self) === savedPlace)
        #expect(saved.depth == 1)
        let explore = try #require(tabs.selectFirstTab(.discover, expecting: ExploreCoordinator.self))
        #expect(explore.depth == 1)
        #expect(explore.descendant(ofType: PlaceCoordinator.self)?.depth == 1)
    }

    @Test("A link from the two-column Lab reinstalls Discover in the same split shell")
    func warmSplitLink() throws {
        let app = AtlasCoordinator(layout: .split).activated()
        app.startExploring()
        let split = try #require(app.descendant(ofType: SplitShellCoordinator.self))
        split.selectSection(.lab)
        #expect(split.contentDestination == nil)

        app.openExampleLink()
        app.activated()

        #expect(app.descendant(ofType: SplitShellCoordinator.self) === split)
        #expect(split.section == .discover)
        #expect(split.contentDestination == .discover)
        #expect(split.selectedPlaceID == "lofoten")
        #expect(split.descendant(ofType: PlaceCoordinator.self)?.topDestination == .highlights)
    }

    @Test("Malformed links leave the current tree intact", arguments: [
        "https://place/kyoto", "atlas://place/unknown", "atlas://place/kyoto/missing", "atlas://place/kyoto/highlights/extra"
    ])
    func invalidLink(url: String) {
        let app = AtlasCoordinator().activated()
        #expect(!app.handle(URL(string: url)!))
        #expect(app.isRoot(.welcome))
    }

    @Test("Discover and Saved resolve the same reusable Places module")
    func independentTabs() throws {
        let app = AtlasCoordinator().activated()
        app.startExploring()
        app.activated()
        let tabs = try #require(app.descendant(ofType: TabShellCoordinator.self))
        let explore = try #require(tabs.selectFirstTab(.discover, expecting: ExploreCoordinator.self))
        explore.choose("dolomites")
        let saved = try #require(tabs.selectFirstTab(.saved, expecting: SavedCoordinator.self))
        saved.choose("kyoto")
        #expect(explore.descendant(ofType: PlaceCoordinator.self)?.placeID == "dolomites")
        #expect(saved.descendant(ofType: PlaceCoordinator.self)?.placeID == "kyoto")
        #expect(explore.depth == 1)
        #expect(saved.depth == 1)
        _ = tabs.shouldSelect(tab: .saved, isReselection: true)
        #expect(saved.depth == 0)
        #expect(explore.depth == 1)
    }

    @Test("Split selection reuses a place but allows another value of the same case")
    func splitSelection() throws {
        let app = AtlasCoordinator(layout: .split).activated()
        app.startExploring()
        app.activated()
        let split = try #require(app.descendant(ofType: SplitShellCoordinator.self))
        let explore = try #require(split.descendant(ofType: ExploreCoordinator.self))
        explore.choose("dolomites")
        let first = try #require(split.descendant(ofType: PlaceCoordinator.self))
        first.showHighlights()
        split.selectSection(.discover)
        #expect(split.descendant(ofType: PlaceCoordinator.self) === first)
        explore.choose("dolomites")
        #expect(split.descendant(ofType: PlaceCoordinator.self) === first)
        explore.choose("kyoto")
        #expect(split.selectedPlaceID == "kyoto")
        #expect(explore.depth == 0)
    }

    @Test("A checkpoint restores navigation without rewinding saved content")
    func checkpoint() throws {
        let app = AtlasCoordinator().activated()
        app.openExampleLink()
        let tabs = try #require(app.descendant(ofType: TabShellCoordinator.self))
        let lab = try #require(tabs.selectFirstTab(.lab, expecting: LabCoordinator.self))
        lab.pushStep(4)
        app.store.toggleSaved("dolomites")
        app.saveCheckpoint()
        let checkpoint = try #require(app.checkpointData)
        app.switchLayout(.split)
        app.store.toggleSaved("dolomites")
        app.restoreCheckpoint()
        app.activated()
        #expect(app.layout == .tabs)
        #expect(!app.store.savedIDs.contains("dolomites"))
        #expect(app.descendant(ofType: LabCoordinator.self)?.depth == 1)
        #expect(app.hierarchyContains(TabShellCoordinator.self, .lab, as: .tab(index: 2, isSelected: true)))
        #expect(app.descendant(ofType: PlaceCoordinator.self)?.topDestination == .highlights)

        let newWindow = AtlasCoordinator().activated()
        newWindow.bootstrap(checkpoint: checkpoint)
        newWindow.activated()
        #expect(newWindow.descendant(ofType: PlaceCoordinator.self)?.placeID == "lofoten")
        #expect(!newWindow.store.savedIDs.contains("dolomites"))
        newWindow.restartWelcome()
        newWindow.bootstrap(checkpoint: checkpoint)
        #expect(newWindow.isRoot(.welcome))
    }

    @Test("Corrupt checkpoints recover without a launch loop")
    func corruptCheckpoint() {
        let app = AtlasCoordinator().activated()
        app.bootstrap(checkpoint: Data("invalid".utf8))
        #expect(!app.hasCheckpoint)
        #expect(app.isRoot(.welcome))
        #expect(app.session.message != nil)
    }

    @Test("Split checkpoints restore selection and the detail's own history")
    func splitCheckpoint() throws {
        let app = AtlasCoordinator(layout: .split).activated()
        app.startExploring()
        app.activated()
        let original = try #require(app.descendant(ofType: SplitShellCoordinator.self))
        original.selectSection(.saved)
        original.openPlace("kyoto")
        original.descendant(ofType: PlaceCoordinator.self)?.showHighlights()
        app.saveCheckpoint()
        app.switchLayout(.tabs)
        app.restoreCheckpoint()
        app.activated()
        let restored = try #require(app.descendant(ofType: SplitShellCoordinator.self))
        #expect(restored.section == .saved)
        #expect(restored.selectedPlaceID == "kyoto")
        #expect(restored.descendant(ofType: PlaceCoordinator.self)?.depth == 1)
        #expect(app.layout == .split)
    }
}
