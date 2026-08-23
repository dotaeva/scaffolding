import SwiftUI

/// One saved place: tap opens the forecast, the info button peeks at it.
struct LocationRow: View {
    @Environment(WeatherStore.self) private var store

    let location: Location
    let open: () -> Void
    let quickLook: () -> Void

    private var today: DayForecast {
        ForecastEngine.tenDays(for: location)[0]
    }

    var body: some View {
        HStack {
            Button(action: open) {
                HStack {
                    VStack(alignment: .leading) {
                        Text(location.name)
                            .font(.headline)
                        Text(location.country)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: today.condition.symbol)
                        .symbolRenderingMode(.multicolor)
                    Text(store.units.format(today.highC))
                        .font(.title3.weight(.medium))
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            Button("Quick look", systemImage: "info.circle", action: quickLook)
                .labelStyle(.iconOnly)
                .buttonStyle(.borderless)
        }
    }
}
