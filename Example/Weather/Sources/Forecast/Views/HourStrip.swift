import SwiftUI

/// Horizontal strip of hourly conditions.
struct HourStrip: View {
    @Environment(WeatherStore.self) private var store

    let hours: [HourForecast]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 18) {
                ForEach(hours) { hour in
                    VStack(spacing: 6) {
                        Text(hour.label)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Image(systemName: hour.condition.symbol)
                            .symbolRenderingMode(.multicolor)
                        Text(store.units.format(hour.temperatureC))
                            .font(.callout.weight(.medium))
                    }
                }
            }
        }
    }
}
