import SwiftUI
import Scaffolding

/// Second step of the add-city sub-flow. Back pops within the sub-flow;
/// Add dismisses the whole coordinator, returning the city.
struct CityConfirmScreen: View {
    @Environment(AddLocationCoordinator.self) private var coordinator
    @Environment(WeatherStore.self) private var store

    let city: Location

    private var today: DayForecast {
        ForecastEngine.tenDays(for: city)[0]
    }

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: today.condition.symbol)
                .font(.system(size: 48))
                .symbolRenderingMode(.multicolor)
            Text(city.name)
                .font(.title.bold())
            Text("\(today.condition.name) · \(store.units.format(today.highC)) right now")
                .foregroundStyle(.secondary)
            Spacer()
            Button("Add \(city.name)") {
                // dismissCoordinator(returning:) — the value lands in the
                // presenter's `await present(_:awaiting:)`.
                coordinator.finish(with: city)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(24)
        .navigationTitle("Confirm")
    }
}
