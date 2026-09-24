import Testing
import Foundation
import Scaffolding
import ScaffoldingTesting
@testable import StinsenParity

/// The `TabCoordinatable` calls the testbed's "Tab shell" section drives.
/// They act on the coordinator *above* the flow — the part a flow-only
/// testbed could never reach.
@MainActor
@Suite("Tab controls")
struct TabControlTests {
    private func makeTabs() -> AuthenticatedCoordinator {
        AuthenticatedCoordinator(user: .preview, toasts: ToastCenter()).activated()
    }

    @Test("selection moves by meta and by index")
    func tabSelection() {
        let tabs = makeTabs()

        tabs.selectFirstTab(.testbed)
        #expect(tabs.selectedTab == .testbed)

        tabs.select(index: 1)
        #expect(tabs.selectedIndex == 1)
    }

    @Test("badges are set and cleared")
    func badges() {
        let tabs = makeTabs()

        tabs.setBadge(3, for: .todos)
        #expect(tabs.badge(for: .todos) == "3")

        tabs.setBadge(nil, for: .todos)
        #expect(tabs.badge(for: .todos) == nil)
    }

    @Test("tabs are appended and removed at runtime")
    func dynamicTabs() {
        let tabs = makeTabs()
        let before = tabs.tabItems.tabs.count

        tabs.appendTab(.testbed)
        #expect(tabs.tabItems.tabs.count == before + 1)

        tabs.removeLastTab(.testbed)
        #expect(tabs.tabItems.tabs.count == before)
        // The original testbed tab is still there — only the appended copy went.
        #expect(tabs.isInTabItems(.testbed))
    }

    @Test("the count that gates removing the last testbed")
    func testbedCount() {
        let tabs = makeTabs()
        // What the testbed row's `.disabled` reads: one testbed means the
        // remove row stays off, because removing it would take the screen
        // doing the removing with it.
        #expect(tabs.tabCount(of: .testbed) == 1)

        tabs.appendTab(.testbed)
        #expect(tabs.tabCount(of: .testbed) == 2)

        tabs.removeLastTab(.testbed)
        #expect(tabs.tabCount(of: .testbed) == 1)
    }
}
