import SwiftUI
import Scaffolding

/// iPad / macOS shell: `NavigationSplitView` with the saved locations in
/// the sidebar and a forecast flow in the detail column. An optional
/// middle "Hourly" column swaps the container between its two- and
/// three-column forms at runtime.
///
/// Never hosted inside a flow — SwiftUI does not support a split view
/// inside a NavigationStack. Here it is a root child, the legal placement.
@MainActor
@Observable
@Scaffoldable(codable: true)
final class WeatherSplitCoordinator: @MainActor SplitCoordinatable {
    var columns = SplitColumns<WeatherSplitCoordinator>(
        sidebar: .sidebar,
        detail: .placeholder,               // shown before any selection
        preferredCompactColumn: .sidebar    // collapsed (compact iPad) start
    )

    let store: WeatherStore

    init(store: WeatherStore) {
        self.store = store
    }

    // MARK: Routes
    // Column assignment lives in the SplitColumns initializer and the
    // setDetail/setContent calls — routes keep plain auto-tracked returns.

    func sidebar() -> some View { LocationSidebar() }

    func placeholder() -> some View {
        ContentUnavailableView(
            "No Location Selected",
            systemImage: "cloud.sun",
            description: Text("Pick a place in the sidebar to see its forecast.")
        )
    }

    /// A child flow in a column builds its own NavigationStack there —
    /// exactly the composition SwiftUI expects — so pushes and modals
    /// inside the detail are ordinary flow calls.
    func forecast(location: Location) -> any Coordinatable {
        ForecastCoordinator(location: location, store: store)
    }

    /// The optional middle column (three-column form).
    func hours(location: Location) -> some View {
        HourlyColumn(location: location)
    }

    /// The same coordinator the iPhone shows as a tab is a sheet here —
    /// the presenter decides, the flow never knows.
    func settings() -> any Coordinatable { SettingsCoordinator(store: store) }

    /// Modal sub-flow returning a value (see addCity below).
    func addLocation() -> any Coordinatable { AddLocationCoordinator() }
}
