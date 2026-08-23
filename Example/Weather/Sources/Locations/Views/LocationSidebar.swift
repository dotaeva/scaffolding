import SwiftUI
import Scaffolding

/// The split view's sidebar. Selection *highlight* is native list state
/// synced with the store; which forecast the detail column shows is the
/// coordinator's job (select → setDetail).
struct LocationSidebar: View {
    @Environment(WeatherSplitCoordinator.self) private var coordinator
    @Environment(WeatherStore.self) private var store

    private var selection: Binding<Location.ID?> {
        Binding(
            get: { store.selectedLocationID },
            set: { id in
                guard let id, let location = store.location(id: id) else { return }
                coordinator.select(location)
            }
        )
    }

    var body: some View {
        List(store.saved, selection: selection) { location in
            HStack {
                VStack(alignment: .leading) {
                    Text(location.name)
                    Text(location.country)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(store.units.format(ForecastEngine.tenDays(for: location)[0].highC))
                    .foregroundStyle(.secondary)
            }
            .tag(location.id)
        }
        .navigationTitle("Weather")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Add City", systemImage: "plus") {
                    coordinator.addCity()          // split modal, awaiting:
                }
            }
            ToolbarItem(placement: .automatic) {
                Button("Hourly Column", systemImage: "sidebar.squares.right") {
                    coordinator.toggleHourlyColumn()   // setContent/removeContent
                }
                .disabled(!coordinator.canShowHourlyColumn)
            }
            ToolbarItem(placement: .automatic) {
                Button("Settings", systemImage: "gearshape") {
                    coordinator.showSettings()     // the tab flow, as a sheet
                }
            }
        }
    }
}
