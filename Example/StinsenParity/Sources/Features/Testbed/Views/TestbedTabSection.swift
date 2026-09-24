import SwiftUI
import Scaffolding

/// The `TabCoordinatable` half of the testbed — present only when the tab
/// shell is the one that was built.
///
/// The shell is an *ancestor* coordinator, so it arrives through the
/// environment from any depth, including from a testbed presented as a
/// sheet. Reading it optionally is what makes this section disappear on
/// iPad without a single `#if`.
struct TestbedTabSection: View {
    @Environment(AuthenticatedCoordinator.self) private var tabs: AuthenticatedCoordinator?

    var body: some View {
        if let tabs {
            Section {
                ReadoutRow("selectedIndex", "\(tabs.selectedIndex)")
                ReadoutRow("tabs.count", "\(tabs.tabItems.tabs.count)")
                ReadoutRow("badge(.todos)", tabs.badge(for: .todos) ?? "—")
                ReadoutRow("isInTabItems(.profile)", String(tabs.isInTabItems(.profile)))

                CallRow("selectFirstTab(.home)", symbol: "house") {
                    tabs.selectFirstTab(.home)
                }
                CallRow("select(index: 1)", symbol: "1.square") {
                    tabs.select(index: 1)
                }
                CallRow("shouldSelect(.testbed, isReselection: true)",
                        symbol: "arrow.uturn.backward") {
                    // Exactly what the tab bar calls on a re-tap. Programmatic
                    // selection bypasses the hook, so this is the only way to
                    // exercise it without a finger.
                    _ = tabs.shouldSelect(tab: .testbed, isReselection: true)
                }
                CallRow("setBadge(3, for: .todos)", symbol: "app.badge") {
                    tabs.setBadge(3, for: .todos)
                }
                CallRow("setBadge(nil, for: .todos)", symbol: "app") {
                    tabs.setBadge(nil, for: .todos)
                }
                CallRow("appendTab(.testbed) — a second testbed",
                        symbol: "plus.rectangle.on.rectangle") {
                    tabs.appendTab(.testbed)
                }
                CallRow("removeLastTab(.testbed)", symbol: "minus.rectangle") {
                    tabs.removeLastTab(.testbed)
                }
                // Only ever removes the *appended* copy: taking the last
                // testbed away would remove the tab this screen is standing
                // in, and nothing here could put it back.
                .disabled(tabs.tabCount(of: .testbed) < 2)
                CallRow("setTabBarVisibility(.hidden)", symbol: "eye.slash") {
                    tabs.setTabBarVisibility(.hidden)
                }
                CallRow("setTabBarVisibility(.visible)", symbol: "eye") {
                    tabs.setTabBarVisibility(.visible)
                }
            } header: {
                Text("Tab shell")
            } footer: {
                Text("The tabs are the shell above this flow, so these reach it "
                     + "with ancestor injection rather than a stored reference. "
                     + "removeLastTab stays disabled until appendTab has made a "
                     + "second testbed — removing the only one would take this "
                     + "screen with it. Hiding the bar leaves the buttons here "
                     + "as the way back, which is how a custom bar is built too.")
            }
        }
    }
}
