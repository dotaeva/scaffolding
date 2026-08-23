import SwiftUI

/// One line of the ten-day list.
struct DayRow: View {
    @Environment(WeatherStore.self) private var store

    let day: DayForecast
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(day.name)
                    .frame(width: 96, alignment: .leading)
                Image(systemName: day.condition.symbol)
                    .symbolRenderingMode(.multicolor)
                    .frame(width: 32)
                Spacer()
                Text(store.units.format(day.lowC))
                    .foregroundStyle(.secondary)
                Text(store.units.format(day.highC))
                    .frame(width: 44, alignment: .trailing)
            }
            .padding(.vertical, 8)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}
