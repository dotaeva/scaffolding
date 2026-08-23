import Testing
import Scaffolding
import ScaffoldingTesting
@testable import Weather

/// The iPad/macOS shell: column replacement, the dynamic content column,
/// visibility, and split-hosted modals.
@MainActor
@Suite("Split view")
struct SplitViewTests {
    private func makeSplit(store: WeatherStore = WeatherStore()) -> WeatherSplitCoordinator {
        WeatherSplitCoordinator(store: store).activated()
    }

    @Test("selection replaces the detail; re-selection keeps it")
    func detailReplacement() {
        let split = makeSplit()

        split.select(.prague)
        let first = split.anySplitColumns.detail?.id
        #expect(split.isDetail(.forecast))

        split.select(.prague)              // same place — guarded, kept
        #expect(split.anySplitColumns.detail?.id == first)

        split.select(.tokyo)               // different place — replaced
        #expect(split.anySplitColumns.detail?.id != first)
    }

    @Test("the hourly column installs and removes at runtime")
    func contentColumn() {
        let split = makeSplit()
        split.select(.prague)

        split.toggleHourlyColumn()
        #expect(split.hierarchyContains(WeatherSplitCoordinator.self, .hours, as: .column(.content)))

        split.select(.oslo)                // selection keeps the column in step
        #expect(split.contentDestination == .hours)

        split.toggleHourlyColumn()
        #expect(!split.anySplitColumns.hasContentColumn)
    }

    @Test("visibility and the compact column are coordinator state")
    func visibility() {
        let split = makeSplit()

        split.setColumnVisibility(.detailOnly)
        #expect(!split.isSidebarVisible)

        split.toggleSidebar()
        #expect(split.isSidebarVisible)

        split.setPreferredCompactColumn(.detail)
        #expect(split.anySplitColumns.preferredCompactColumn == .detail)
    }

    @Test("the sidebar column itself can be replaced")
    func sidebarReplacement() {
        let split = makeSplit()
        #expect(split.sidebarDestination == .sidebar)

        // Structural, so rarely done — but the API mirrors the other columns.
        split.setSidebar(.sidebar, policy: .distinct)   // same case — kept
        #expect(split.sidebarDestination == .sidebar)
    }

    @Test("settings presents as a split modal, deduplicated")
    func settingsSheet() {
        let split = makeSplit()

        split.showSettings()
        split.showSettings()               // .distinct — skipped

        #expect(split.isPresentingModal)
        #expect(split.anySplitColumns.modals.count == 1)
        let settings = split.descendant(ofType: SettingsCoordinator.self)
        #expect(settings?.routeType == .sheet)
    }

    @Test("addCity awaits the sub-flow and selects the new place")
    func addCity() async {
        let store = WeatherStore()
        let split = makeSplit(store: store)
        let lisbon = Location.searchable[0]

        split.addCity()
        await waitUntil { split.isPresentingModal }

        split.descendant(ofType: AddLocationCoordinator.self)?.finish(with: lisbon)

        await waitUntil { store.selectedLocationID == lisbon.id }
        #expect(store.saved.contains(lisbon))
        #expect(split.isDetail(.forecast))
    }
}
