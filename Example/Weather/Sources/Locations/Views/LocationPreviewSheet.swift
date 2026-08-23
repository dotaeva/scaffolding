import SwiftUI
import Scaffolding

/// View-only quick look — a single screen, so it stays a native-style
/// sheet without a child coordinator. Closing goes through the presenter
/// (dismissModal), the counterpart of present(_:as:).
struct LocationPreviewSheet: View {
    @Environment(LocationsCoordinator.self) private var coordinator
    @Environment(WeatherStore.self) private var store
    @Environment(\.destination) private var destination

    let location: Location

    private var today: DayForecast {
        ForecastEngine.tenDays(for: location)[0]
    }

    var body: some View {
        VStack(spacing: 12) {
            Text(location.name)
                .font(.title2.bold())
            Image(systemName: today.condition.symbol)
                .font(.system(size: 44))
                .symbolRenderingMode(.multicolor)
            Text(store.units.format(today.highC))
                .font(.system(size: 48, weight: .thin))
            Text(today.summary)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            // How this screen was reached, straight from the environment.
            Text("routeType: .\(String(describing: destination.routeType))")
                .font(.caption2.monospaced())
                .foregroundStyle(.tertiary)
            Button("Done") {
                coordinator.closeQuickLook()   // presenter-side dismissal
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(24)
        .presentationBackground(.thinMaterial)
    }
}
