import SwiftUI
import AtlasDomain
import AtlasDesign

struct PlaceScreen: View {
    @Environment(PlaceCoordinator.self) private var coordinator
    var body: some View {
        if let place = PlaceCatalog.place(coordinator.placeID) {
            AtlasForm {
                PlaceDetails(place: place)
                PlaceActions()
            }
            .navigationTitle(place.name)
            .modifier(InlineNavigationTitle())
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { coordinator.store.toggleSaved(place.id) } label: {
                        Label(coordinator.store.savedIDs.contains(place.id) ? "Unsave place" : "Save place", systemImage: coordinator.store.savedIDs.contains(place.id) ? "bookmark.fill" : "bookmark")
                    }
                    .accessibilityIdentifier("place.save")
                }
            }
        } else {
            ContentUnavailableView("Place not found", systemImage: "map", description: Text("Return to Discover to choose another place."))
        }
    }
}

private struct PlaceDetails: View {
    let place: Place
    var body: some View {
        Section(place.name) {
            Text(place.caption).font(.headline)
            Text(place.story)
        }
        Section("Location") {
            LabeledContent("Country", value: place.region)
            LabeledContent("Coordinates", value: place.coordinates)
        }
    }
}

private struct PlaceActions: View {
    @Environment(PlaceCoordinator.self) private var coordinator
    var body: some View {
        Section {
            Button("Plan a journey", systemImage: "suitcase.rolling") { coordinator.plan() }
                .accessibilityIdentifier("place.plan")
            Button("Read the field notes", systemImage: "text.book.closed") { coordinator.showHighlights() }
                .accessibilityIdentifier("place.highlights")
        }
    }
}

struct HighlightsScreen: View {
    @Environment(PlaceCoordinator.self) private var coordinator
    var body: some View {
        AtlasForm {
            if let place = PlaceCatalog.place(coordinator.placeID) {
                Section(place.name) {
                    ForEach(place.highlights, id: \.self) { highlight in
                        Label(highlight, systemImage: "mappin")
                    }
                }
                Section {
                    Button("Plan a journey", systemImage: "suitcase.rolling") { coordinator.plan() }
                        .accessibilityIdentifier("place.plan")
                }
            }
        }
        .navigationTitle("Field notes")
        .modifier(InlineNavigationTitle())
        .accessibilityIdentifier("place.highlights.screen")
    }
}
