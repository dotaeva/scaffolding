import SwiftUI
import Scaffolding

/// Root of the add-city sub-flow. The search text is view-local UI state —
/// which screen shows is the coordinator's business, what's typed into a
/// field is not.
struct CitySearchScreen: View {
    @Environment(AddLocationCoordinator.self) private var coordinator
    @Environment(WeatherStore.self) private var store

    @State private var query = ""

    private var results: [Location] {
        let unsaved = Location.searchable.filter { !store.saved.contains($0) }
        guard !query.isEmpty else { return unsaved }
        return unsaved.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        List(results) { city in
            Button {
                coordinator.select(city)   // push within the sub-flow
            } label: {
                VStack(alignment: .leading) {
                    Text(city.name)
                    Text(city.country)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .searchable(text: $query, prompt: "City name")
        .navigationTitle("Add City")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    coordinator.cancel()   // presenter's awaiting: → nil
                }
            }
        }
    }
}
