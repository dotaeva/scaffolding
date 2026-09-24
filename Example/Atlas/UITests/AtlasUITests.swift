import XCTest
import UIKit

@MainActor
final class AtlasUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    func testSavedJourneyCanEditUndoAndSurviveRelaunch() throws {
        try XCTSkipUnless(UIDevice.current.userInterfaceIdiom == .phone, "Exercises independent iPhone tabs")
        launch()
        capture("Welcome")
        tap("welcome.begin")
        capture("Discover")
        tap("place.dolomites")
        tap("place.save")
        tap("place.plan")
        tap("planner.days-Increment")
        tap("planner.days-Increment")
        selectPace("A little of both")
        capture("Planner details")
        tap("planner.review")
        assertStatistic("Time away", value: "5 days")
        assertStatistic("Pace", value: "A little of both")
        capture("Planner review")
        tap("planner.finish")
        assertFeedbackBelowNavigationBar()
        XCTAssertEqual(app.buttons["notice.action"].label, "View journey")
        capture("Saved feedback")
        tap("notice.action")
        XCTAssertTrue(app.navigationBars["Your journey"].waitForExistence(timeout: 5))
        assertStatistic("Time away", value: "5 days")
        capture("Saved journey")
        tap("journey.edit")
        XCTAssertEqual(app.steppers["planner.days"].value as? String, "5")
        XCTAssertTrue(paceOption("A little of both").isSelected)
        tap("planner.days-Increment")
        tap("planner.review")
        tap("planner.finish")
        assertStatistic("Time away", value: "6 days")
        tap("journey.remove")
        XCTAssertFalse(app.buttons["journey.dolomites"].exists)
        XCTAssertEqual(app.buttons["notice.action"].label, "Undo")
        tap("notice.action")
        tap("tab.saved")
        XCTAssertEqual(app.buttons.matching(identifier: "journey.dolomites").count, 1, "Editing and Undo must not duplicate the journey")
        XCTAssertTrue(app.buttons["journey.dolomites"].label.contains("6 days · A little of both"))
        capture("Journey restored by Undo")

        capture("Before normal relaunch")
        app.terminate()
        app.launchArguments = ["--atlas-testing"]
        app.launch()
        capture("Normal relaunch")
        XCTAssertTrue(app.buttons["tab.saved"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["welcome.begin"].exists, "The introduction must not repeat on normal launch")
        tap("tab.saved")
        XCTAssertEqual(app.buttons.matching(identifier: "journey.dolomites").count, 1)
        XCTAssertTrue(app.buttons["journey.dolomites"].label.contains("6 days · A little of both"))
        tap("journey.dolomites")
        assertStatistic("Time away", value: "6 days")
        tap("journey.place")
        XCTAssertEqual(app.buttons["place.save"].label, "Unsave place")
        capture("Collection retained after relaunch")
    }

    func testLabDeepLinkAndCheckpoint() throws {
        try XCTSkipUnless(UIDevice.current.userInterfaceIdiom == .phone, "Exercises the iPhone tab checkpoint")
        launch()
        tap("welcome.begin")
        tap("tab.lab")
        capture("Lab")
        tap("lab.deeplink")
        XCTAssertTrue(app.navigationBars["Field notes"].waitForExistence(timeout: 5))
        capture("Deep link")
        tap("tab.lab")
        tap("lab.checkpoint.save")
        tap("notice.dismiss")
        tap("tab.discover")
        tap("tab.discover")
        tap("place.dolomites")
        tap("place.save")
        XCTAssertEqual(app.buttons["place.save"].label, "Unsave place")
        tap("tab.lab")
        tap("lab.push")
        XCTAssertTrue(app.navigationBars["Chapter 1"].waitForExistence(timeout: 5))
        tap("lab.root")
        tap("lab.checkpoint.restore")
        tap("notice.dismiss")
        tap("tab.discover")
        XCTAssertTrue(app.navigationBars["Field notes"].waitForExistence(timeout: 5))
        capture("Navigation restored with latest collection")
        tap("tab.saved")
        XCTAssertTrue(app.buttons["place.dolomites"].waitForExistence(timeout: 5), "Restoring navigation must retain newer collection changes")
    }

    func testPlannerCanCancelFromSheetReviewAndFullScreen() throws {
        try XCTSkipUnless(UIDevice.current.userInterfaceIdiom == .phone, "Exercises iPhone sheet and full-screen presentation")
        launch()
        tap("welcome.begin")
        tap("place.dolomites")
        tap("place.plan")
        XCTAssertTrue(app.buttons["planner.cancel"].waitForExistence(timeout: 5))
        tap("planner.review")
        tap("planner.cancel")
        XCTAssertTrue(app.navigationBars["The Dolomites"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["planner.finish"].exists)

        tap("tab.lab")
        tap("lab.fullscreen")
        XCTAssertTrue(app.buttons["planner.review"].waitForExistence(timeout: 5))
        capture("Full screen planner")
        tap("planner.cancel")
        XCTAssertTrue(app.navigationBars["Lab"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["planner.review"].exists)
    }

    func testLargestDynamicTypePaceAndReview() throws {
        try XCTSkipUnless(UIDevice.current.userInterfaceIdiom == .phone, "Exercises iPhone accessibility text layout")
        launch(arguments: ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"])
        capture("Largest text welcome")
        tap("welcome.begin")
        tap("place.dolomites")
        tap("place.plan")
        selectPace("A little of both")
        XCTAssertTrue(paceOption("A little of both").isSelected)
        capture("Largest text balanced pace")
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.8))
            .press(forDuration: 0.1, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.45)))
        let balancedPace = paceOption("A little of both")
        XCTAssertGreaterThanOrEqual(balancedPace.frame.minY, app.navigationBars["Plan a journey"].frame.maxY)
        XCTAssertLessThanOrEqual(balancedPace.frame.maxY, app.frame.maxY)
        capture("Largest text balanced pace fully visible")
        tap("planner.review")
        assertStatistic("Pace", value: "A little of both")
        reach(app.buttons["planner.finish"], name: "planner.finish")
        capture("Largest text review")
        tap("planner.cancel")
        XCTAssertTrue(app.navigationBars["The Dolomites"].waitForExistence(timeout: 5))
        tap("tab.saved")
        selectCollection("Journeys")
        XCTAssertTrue(app.staticTexts["No journeys"].exists)
        capture("Largest text Saved collections")
        selectCollection("Places")
        XCTAssertTrue(app.buttons["place.kyoto"].exists)
    }

    func testDarkAppearanceJourneyScreens() throws {
        try XCTSkipUnless(UIDevice.current.userInterfaceIdiom == .phone, "Captures iPhone dark appearance")
        let previousAppearance = XCUIDevice.shared.appearance
        defer { XCUIDevice.shared.appearance = previousAppearance }
        launch()
        XCUIDevice.shared.appearance = .dark
        capture("Dark welcome")
        tap("welcome.begin")
        capture("Dark Discover")
        tap("place.dolomites")
        capture("Dark place")
        tap("place.highlights")
        capture("Dark field notes")
        tap("place.plan")
        capture("Dark planner")
        tap("planner.cancel")
    }

    func testSplitViewJourneyOnIPad() throws {
        try XCTSkipUnless(UIDevice.current.userInterfaceIdiom == .pad, "Exercises the iPad split layout")
        launch()
        capture("Before landscape")
        XCUIDevice.shared.orientation = .landscapeLeft
        defer { XCUIDevice.shared.orientation = .portrait }
        capture("After landscape")
        tap("welcome.begin")
        XCTAssertTrue(app.buttons["sidebar.discover"].waitForExistence(timeout: 5))
        tap("place.dolomites")
        XCTAssertTrue(app.navigationBars["The Dolomites"].waitForExistence(timeout: 5))
        capture("iPad split view")
        tap("place.plan")
        XCTAssertTrue(app.buttons["planner.cancel"].waitForExistence(timeout: 5))
        tap("planner.review")
        capture("iPad planner")
        tap("planner.finish")
        tap("notice.dismiss")
        tap("sidebar.saved")
        XCTAssertTrue(app.buttons["journey.dolomites"].waitForExistence(timeout: 5))
        capture("iPad saved journey")
    }

    private func launch(arguments: [String] = []) {
        app.launchArguments = ["--atlas-fresh-session"] + arguments
        app.launch()
        capture("Launch")
    }

    private func assertFeedbackBelowNavigationBar(file: StaticString = #filePath, line: UInt = #line) {
        let dismiss = app.buttons["notice.dismiss"]
        XCTAssertTrue(dismiss.waitForExistence(timeout: 5), file: file, line: line)
        let navigationBar = app.navigationBars.firstMatch
        XCTAssertGreaterThanOrEqual(dismiss.frame.minY, navigationBar.frame.maxY, "Feedback covers navigation", file: file, line: line)
        XCTAssertGreaterThanOrEqual(dismiss.frame.width, 44, file: file, line: line)
        XCTAssertGreaterThanOrEqual(dismiss.frame.height, 44, file: file, line: line)
    }

    private func tap(_ identifier: String, file: StaticString = #filePath, line: UInt = #line) {
        tap(app.buttons[identifier].firstMatch, name: identifier, file: file, line: line)
    }

    private func paceOption(_ label: String) -> XCUIElement {
        app.buttons.matching(identifier: "planner.pace")
            .matching(NSPredicate(format: "label == %@", label)).firstMatch
    }

    private func selectPace(_ label: String) {
        tap(paceOption(label), name: "Pace: \(label)")
    }

    private func selectCollection(_ label: String) {
        tap(app.segmentedControls["saved.collection"].buttons[label], name: "Collection: \(label)")
    }

    private func assertStatistic(_ label: String, value: String, file: StaticString = #filePath, line: UInt = #line) {
        // Native LabeledContent exposes its label and value as one element.
        XCTAssertTrue(app.staticTexts["\(label), \(value)"].exists, file: file, line: line)
    }

    private func tap(_ element: XCUIElement, name: String, file: StaticString = #filePath, line: UInt = #line) {
        capture("Before \(name)")
        reach(element, name: name, file: file, line: line)
        element.tap()
        capture("After \(name)")
    }

    private func reach(_ element: XCUIElement, name: String, file: StaticString = #filePath, line: UInt = #line) {
        for attempt in 0..<8 {
            if element.exists && element.isHittable { return }
            if element.exists && element.frame.midY < app.frame.midY { app.swipeDown() } else { app.swipeUp() }
            capture("Scroll \(attempt + 1) to \(name)")
        }
        XCTAssertTrue(element.isHittable, "Cannot reach \(name)", file: file, line: line)
    }

    private func capture(_ name: String) {
        let hierarchy = XCTAttachment(string: app.debugDescription)
        hierarchy.name = "\(name) hierarchy"
        hierarchy.lifetime = .keepAlways
        add(hierarchy)
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
