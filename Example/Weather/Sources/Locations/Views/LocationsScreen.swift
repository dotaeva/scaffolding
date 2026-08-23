import SwiftUI
import Scaffolding

struct LocationsScreen: View {
    @Environment(LocationsCoordinator.self) private var coordinator
    @Environment(WeatherStore.self) private var store

    var body: some View {
        List {
            ForEach(store.saved) { location in
                LocationRow(location: location) {
                    // Pushes a whole ForecastCoordinator onto this flow.
                    coordinator.showForecast(for: location)
                } quickLook: {
                    coordinator.quickLook(location)
                }
            }
            .onDelete { offsets in
                for index in offsets {
                    store.remove(store.saved[index])
                }
            }
        }
        .navigationTitle("Locations")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Add City", systemImage: "plus") {
                    coordinator.addCity()   // awaits the sub-flow's result
                }
            }
        }
    }
}
