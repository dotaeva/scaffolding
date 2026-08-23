import SwiftUI
import Scaffolding

/// A pushed day. Same-case pushes chain (Next day), replaceLast swaps the
/// top so back skips, and the inspector below exercises every pop.
struct DayDetailScreen: View {
    @Environment(ForecastCoordinator.self) private var coordinator
    @Environment(WeatherStore.self) private var store

    let day: DayForecast

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(spacing: 4) {
                    Image(systemName: day.condition.symbol)
                        .font(.system(size: 40))
                        .symbolRenderingMode(.multicolor)
                    Text("\(store.units.format(day.highC)) / \(store.units.format(day.lowC))")
                        .font(.system(size: 40, weight: .thin))
                    Text(day.summary)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 8)

                HourStrip(hours: day.hours)
                    .weatherCard()

                if day.index < 9 {
                    VStack(spacing: 8) {
                        Button("Next day (push)") {
                            // .always on purpose — day details stack up.
                            coordinator.openNext(after: day)
                        }
                        Button("Next day (replace — back skips this one)") {
                            coordinator.skipToNext(after: day)
                        }
                    }
                    .buttonStyle(.bordered)
                }

                ForecastStackInspector()
            }
            .padding(16)
        }
        .navigationTitle(day.name)
        .skyBackground(day.condition)   // each day brings its own palette
    }
}

#Preview("Pushed mid-flow") {
    // Seeded FlowStack(root:pushing:) — the flow starts one screen deep.
    ForecastCoordinator(
        location: .prague,
        store: WeatherStore(),
        startingAt: ForecastEngine.tenDays(for: .prague)[2]
    ).view
    .environment(WeatherStore())
}
