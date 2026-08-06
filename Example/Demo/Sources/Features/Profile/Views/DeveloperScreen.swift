import SwiftUI
import Scaffolding

/// Exercises the flow, tab-mutation, selection, badge and debugging APIs
/// against the live coordinators.
struct DeveloperScreen: View {
    @Environment(ProfileCoordinator.self) private var coordinator
    @Environment(MainTabCoordinator.self) private var tabs
    @Environment(AppCoordinator.self) private var appCoordinator
    @Environment(\.destination) private var destination

    @State private var nativeBarVisible = false

    var body: some View {
        List {
            Section("Flow (profile stack)") {
                // Pushing the same case repeatedly is fine — each tap adds
                // another developer screen to walk back through.
                Button("route(to: .developer)") { coordinator.openDeveloper() }
                Button("replaceLast(with: .developer)") {
                    // Swaps this screen for a fresh instance; back skips it.
                    coordinator.replaceLast(with: .developer)
                }
                Button("pop()") { coordinator.pop() }
                if coordinator.depth >= 2 {
                    Button("pop(2)") { coordinator.pop(2) }
                }
                Button("popToRoot()") { coordinator.popToRoot() }
                LabeledContent("depth", value: "\(coordinator.depth)")
                LabeledContent("topDestination", value: String(describing: coordinator.topDestination))
            }

            Section("Modals (profile flow)") {
                // The same route, presented instead of pushed — the
                // presenter picks push vs sheet vs cover per call site.
                Button("present(.developer, as: .sheet)") {
                    coordinator.present(.developer, as: .sheet)
                }
                Button("present(.developer, as: .fullScreenCover)") {
                    coordinator.present(.developer, as: .fullScreenCover)
                }
                Button("dismissModal()") {
                    // Closes the topmost modal; safe no-op when nothing is up.
                    coordinator.dismissModal()
                }
                Button("dismissAllModals()") {
                    coordinator.dismissAllModals()
                }
            }

            Section("Dynamic tabs") {
                // Duplicates are allowed — the same case can appear as
                // several tabs; first/last/id selectors disambiguate.
                Button("appendTab(.promo)") { tabs.appendTab(.promo) }
                Button("insertTab(.promo, at: 1)") { tabs.insertTab(.promo, at: 1) }
                Button("removeFirstTab(.promo)") { tabs.removeFirstTab(.promo) }
                Button("removeLastTab(.promo)") { tabs.removeLastTab(.promo) }
                Button("Reset tabs") {
                    // setTabs resolves fresh destinations, so badges (keyed to
                    // the old tabs) and the selection do not survive it.
                    tabs.setTabs([.home, .cards, .invest, .profile])
                }
                LabeledContent("isInTabItems(.promo)", value: "\(tabs.isInTabItems(.promo))")
            }

            Section("Selection") {
                Button("selectFirstTab(.cards)") { tabs.selectFirstTab(.cards) }
                Button("selectLastTab(.promo)") {
                    // No-op unless a promo tab exists; picks the last match.
                    tabs.selectLastTab(.promo)
                }
                Button("select(index: last)") {
                    tabs.select(index: tabs.tabItems.tabs.count - 1)
                }
                Button("select(id: first tab)") {
                    // UUID-based selection — the disambiguator when the same
                    // case appears as multiple tabs.
                    if let id = tabs.tabItems.tabs.first?.id {
                        tabs.select(id: id)
                    }
                }
                Button("Home + pop to root") {
                    // Typed callback hands over the tab's child coordinator.
                    tabs.selectFirstTab(.home) { (home: HomeCoordinator) in
                        home.popToRoot()
                    }
                }
            }

            Section("Badges") {
                Button("setBadge(\"NEW\", for: .cards)") {
                    tabs.setBadge("NEW", for: .cards)
                }
                Button("Clear Cards badge") {
                    // Int overload: 0 clears, matching SwiftUI's badge(_:).
                    tabs.setBadge(0, for: .cards)
                }
                LabeledContent("badge(for: .cards)", value: tabs.badge(for: .cards) ?? "nil")
            }

            Section("Native bar") {
                Toggle("Native tab bar", isOn: $nativeBarVisible)
                    // The list inherits the app-wide white tint; a white
                    // track would hide the white knob.
                    .tint(.green)
                    .onChange(of: nativeBarVisible) { _, visible in
                        // The glass bar hides while the native bar is shown
                        // (MainTabCoordinator.showsGlassBar). The routes are
                        // label-less, so the native tabs render empty — the
                        // toggle exists to demo the API.
                        tabs.setTabBarVisibility(visible ? .visible : .hidden)
                    }
            }

            Section("Orientation") {
                // Coordinator-side vs view-side: this screen can be pushed
                // or presented (see the Modals section), and the two values
                // diverge accordingly.
                LabeledContent("destination.routeType", value: String(describing: destination.routeType))
                LabeledContent("profile.routeType", value: String(describing: coordinator.routeType))
                LabeledContent("tabs.routeType", value: String(describing: tabs.routeType))
                LabeledContent("isPresentingModal", value: "\(coordinator.isPresentingModal)")
                Button("Dump hierarchy") {
                    // Same sheet a device shake opens (⌃⌘Z in the simulator).
                    appCoordinator.showHierarchyDump()
                }
                // Visible only when this screen is presented modally.
                AdaptiveDismissButton()
            }
        }
        .scrollEdgeEffectStyle(.soft, for: .top)
        .scrollContentBackground(.hidden)
        .background(ScreenBackground())
        .navigationTitle("Developer")
        .navigationBarTitleDisplayMode(.inline)
    }
}
