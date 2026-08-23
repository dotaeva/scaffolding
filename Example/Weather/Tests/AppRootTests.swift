import Testing
import Foundation
import Scaffolding
import ScaffoldingTesting
@testable import Weather

/// Root swaps, root modals, and deep links — against the shipping
/// AppCoordinator, no test doubles. Layout is injected, so both shells
/// are covered on every platform.
@MainActor
@Suite("App root")
struct AppRootTests {

    @Test("starts in onboarding, finishing swaps to main")
    func onboardingSwap() {
        let app = AppCoordinator(layout: .tabs).activated()
        #expect(app.isRoot(.onboarding))

        app.finishOnboarding()

        #expect(app.isRoot(.main))
        #expect(app.descendant(ofType: MainTabCoordinator.self) != nil)
    }

    @Test("the split layout builds a split shell")
    func splitLayout() {
        let app = AppCoordinator(layout: .split).activated()
        app.finishOnboarding()

        #expect(app.descendant(ofType: WeatherSplitCoordinator.self) != nil)
        #expect(app.descendant(ofType: MainTabCoordinator.self) == nil)
    }

    @Test("a coordinator deep in the tree resets onboarding via ancestor(ofType:)")
    func ancestorReachesTheRoot() {
        let app = AppCoordinator(layout: .tabs).activated()
        app.finishOnboarding()
        let settings = app.descendant(ofType: MainTabCoordinator.self)?
            .selectFirstTab(.settings, expecting: SettingsCoordinator.self)

        settings?.resetOnboarding()

        #expect(app.isRoot(.onboarding))
    }

    @Test("hierarchyRoot climbs to the app coordinator from any depth")
    func hierarchyRootClimbs() {
        let app = AppCoordinator(layout: .tabs).activated()
        app.finishOnboarding()
        let settings = app.descendant(ofType: MainTabCoordinator.self)?
            .selectFirstTab(.settings, expecting: SettingsCoordinator.self)

        #expect(settings?.hierarchyRoot === app)
    }

    @Test("the debug sheet is a root modal, deduplicated by .distinct")
    func rootModal() {
        let app = AppCoordinator(layout: .tabs).activated()

        app.showHierarchyDump()
        app.showHierarchyDump()   // .distinct — skipped

        #expect(app.anyRoot.modals.count == 1)
        app.dismissModal()
        #expect(!app.isPresentingModal)
    }

    @Test("weather://location deep link lands in the Locations tab")
    func locationDeepLink() {
        let app = AppCoordinator(layout: .tabs).activated()
        app.finishOnboarding()

        app.handle(URL(string: "weather://location/lisbon")!)

        #expect(app.hierarchyContains(MainTabCoordinator.self, .locations, as: .tab(index: 1, isSelected: true)))
        #expect(app.hierarchyContains(LocationsCoordinator.self, .forecast, as: .push))
        #expect(app.store.saved.contains { $0.id == "lisbon" })
    }

    @Test("weather://day deep link opens a pushed day in the split detail")
    func dayDeepLink() {
        let app = AppCoordinator(layout: .split).activated()
        app.finishOnboarding()

        app.handle(URL(string: "weather://day/2")!)

        #expect(app.hierarchyContains(WeatherSplitCoordinator.self, .forecast, as: .column(.detail)))
        let forecast = app.descendant(ofType: ForecastCoordinator.self)
        #expect(forecast?.topDestination == .day)
    }

    @Test("deep links are ignored before onboarding completes")
    func deepLinkGate() {
        let app = AppCoordinator(layout: .tabs).activated()

        app.handle(URL(string: "weather://day/2")!)

        #expect(app.isRoot(.onboarding))
    }
}
