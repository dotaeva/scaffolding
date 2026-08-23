import SwiftUI
import Scaffolding

/// The split view's optional middle column — installed by setContent and
/// removed by removeContent (the container swaps between its two- and
/// three-column forms).
struct HourlyColumn: View {
    @Environment(WeatherStore.self) private var store

    let location: Location

    private var today: DayForecast {
        ForecastEngine.tenDays(for: location)[0]
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(today.hours) { hour in
                    HStack {
                        Text(hour.label)
                            .foregroundStyle(.secondary)
                            .frame(width: 56, alignment: .leading)
                        Image(systemName: hour.condition.symbol)
                            .symbolRenderingMode(.multicolor)
                        Spacer()
                        Text(store.units.format(hour.temperatureC))
                            .font(.callout.weight(.medium))
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                }
            }
        }
        .navigationTitle("Hourly · \(location.name)")
        .skyBackground(today.condition)
    }
}
