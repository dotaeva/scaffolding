import SwiftUI
import Scaffolding

/// Push/pop workhorse: one location's forecast. Shown as the iPhone
/// Weather tab, pushed from the Locations list, and installed in the
/// split view's detail column — same coordinator, three placements.
@MainActor
@Observable
@Scaffoldable(codable: true)
final class ForecastCoordinator: @MainActor FlowCoordinatable {
    var stack: FlowStack<ForecastCoordinator>

    let store: WeatherStore
    /// Written only by switchLocation — views treat it as read-only.
    var location: Location

    /// Written by DayPickerScreen, consumed after routeAndWait resumes.
    var pickedDay: DayForecast?

    init(location: Location, store: WeatherStore) {
        self.location = location
        self.store = store
        stack = FlowStack(root: .today(location: location))
    }

    /// FlowStack(root:pushing:) seeds pushed destinations when the stack
    /// is first set up — mid-flow previews and deterministic starts. The
    /// macro synthesises no init(initialRoute:); write it yourself.
    init(location: Location, store: WeatherStore, startingAt day: DayForecast) {
        self.location = location
        self.store = store
        stack = FlowStack(root: .today(location: location), pushing: [.day(day: day)])
    }

    // MARK: Routes
    // Route payloads are Codable + Equatable, so `codable: true` works.

    func today(location: Location) -> some View { ForecastScreen(location: location) }
    func day(day: DayForecast) -> some View { DayDetailScreen(day: day) }
    func dayPicker() -> some View { DayPickerScreen() }
    func radar() -> some View { RadarScreen() }
    func alert() -> some View { SevereAlertSheet() }
}

// MARK: - Data

extension ForecastCoordinator {
    var days: [DayForecast] { ForecastEngine.tenDays(for: location) }
    var todayCondition: Condition { days[0].condition }
}

// MARK: - Chrome

extension ForecastCoordinator {
    /// Flow-wide base layer behind the whole NavigationStack. Containers
    /// that paint their own opaque background (pushed destinations, the
    /// TabView) cover it, so screens also apply their own palette — this
    /// keeps the flow themed wherever the base does show through (e.g.
    /// the split view's detail root).
    func customize(_ view: AnyView) -> some View {
        view.skyBackground(todayCondition)
    }
}
