import XCTest

/// Locks down the row-tap behaviour that took several tries to get right.
///
/// A `Button` with a custom label in a list row is easy to break in ways
/// unit tests cannot see: `.buttonStyle(.plain)` removes the row's own
/// activation and leaves the label's gesture, which the scroll view delays,
/// so the first tap goes nowhere. Only a real synthesized tap catches that,
/// which is what this target exists for.
final class RowTapTests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    private func launchToTestbed() -> XCUIApplication {
        let app = XCUIApplication()
        app.launch()
        // The login screen ships with its credentials filled in.
        let login = app.buttons["Login"]
        if login.waitForExistence(timeout: 5) { login.tap() }

        let testbed = app.tabBars.buttons["Testbed"]
        XCTAssertTrue(testbed.waitForExistence(timeout: 10))
        testbed.tap()
        return app
    }

    private func scroll(to element: XCUIElement, in app: XCUIApplication) {
        var attempts = 0
        while !element.isHittable, attempts < 25 {
            app.swipeUp()
            attempts += 1
        }
        XCTAssertTrue(element.isHittable, "never reached \(element)")
    }

    /// The readout row two lines above the button, which is the cheapest
    /// proof the call ran.
    private func badgeReadoutShows(_ value: String, in app: XCUIApplication) -> Bool {
        app.staticTexts.allElementsBoundByIndex
            .contains { $0.label == "badge(.todos), \(value)" }
    }

    func testTheWholeRowIsTheHitTarget() throws {
        let app = launchToTestbed()
        let row = app.buttons["setBadge(3, for: .todos)"]
        scroll(to: row, in: app)

        let cell = app.cells.containing(.button, identifier: "setBadge(3, for: .todos)")
            .element(boundBy: 0)
        XCTAssertEqual(row.frame, cell.frame,
                       "the button must fill its row, or taps near the edge do nothing")
    }

    func testOneTapAtTheFarEdgeRunsTheCall() throws {
        let app = launchToTestbed()
        let row = app.buttons["setBadge(3, for: .todos)"]
        scroll(to: row, in: app)
        XCTAssertTrue(badgeReadoutShows("—", in: app), "expected no badge to start with")

        // 97% across: the empty space a finger lands on, not the label.
        row.coordinate(withNormalizedOffset: CGVector(dx: 0.97, dy: 0.5)).tap()

        XCTAssertTrue(
            badgeReadoutShows("3", in: app),
            "one tap at the trailing edge did not run setBadge"
        )
    }

    func testOneTapAtTheCentreRunsTheCall() throws {
        let app = launchToTestbed()
        let row = app.buttons["setBadge(3, for: .todos)"]
        scroll(to: row, in: app)

        row.tap()

        XCTAssertTrue(
            badgeReadoutShows("3", in: app),
            "one tap did not run setBadge"
        )
    }
}
