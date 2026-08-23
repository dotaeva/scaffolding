import SwiftUI
import Scaffolding

/// The flow's root: current conditions, today's hours, ten-day list.
struct ForecastScreen: View {
    @Environment(ForecastCoordinator.self) private var coordinator
    @Environment(WeatherStore.self) private var store

    let location: Location

    private var today: DayForecast { coordinator.days[0] }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                header
                if store.hasUnacknowledgedAlert {
                    alertBanner
                }
                HourStrip(hours: today.hours)
                    .weatherCard()
                VStack(spacing: 0) {
                    ForEach(coordinator.days) { day in
                        DayRow(day: day) {
                            coordinator.open(day)   // push, double-tap guarded
                        }
                    }
                }
                .weatherCard()
                Button("Jump to a day…") {
                    coordinator.chooseDay()         // routeAndWait
                }
                .font(.callout)
            }
            .padding(16)
        }
        .navigationTitle(location.name)
        .skyBackground(today.condition)
        .toolbar { toolbarContent }
    }

    private var header: some View {
        VStack(spacing: 4) {
            Image(systemName: today.condition.symbol)
                .font(.system(size: 44))
                .symbolRenderingMode(.multicolor)
            Text(store.units.format(today.highC))
                .font(.system(size: 64, weight: .thin))
            Text("\(today.condition.name) · L: \(store.units.format(today.lowC))")
                .foregroundStyle(.secondary)
        }
        .padding(.top, 8)
    }

    private var alertBanner: some View {
        Button {
            // presentAndWait: radar opens once the warning is acknowledged.
            coordinator.reviewAlertThenRadar()
        } label: {
            Label("Severe weather nearby — review the warning", systemImage: "exclamationmark.triangle.fill")
                .font(.callout.weight(.semibold))
                .weatherCard()
        }
        .buttonStyle(.plain)
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button("Radar", systemImage: "dot.radiowaves.left.and.right") {
                coordinator.showRadar()             // fullScreenCover
            }
        }
        ToolbarItem(placement: .secondaryAction) {
            Menu("Switch city", systemImage: "arrow.triangle.2.circlepath") {
                ForEach(store.saved) { city in
                    Button(city.name) {
                        coordinator.switchLocation(city)   // flow setRoot
                    }
                }
            }
        }
    }
}
