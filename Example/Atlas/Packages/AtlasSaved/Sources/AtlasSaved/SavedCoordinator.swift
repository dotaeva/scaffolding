import SwiftUI
import Scaffolding
import AtlasDomain
import AtlasDesign
import AtlasPlaces

@MainActor @Observable @Scaffoldable(codable: true)
public final class SavedCoordinator: FlowCoordinatable {
    public var stack = FlowStack<SavedCoordinator>(root: .saved)
    public let store: AtlasStore
    public let session: AtlasSessionContext?
    private weak var selection: (any AtlasSelectionDelegate)?
    public var isColumn: Bool { selection != nil }
    public var selectedPlaceID: String? { selection?.selectedPlaceID }
    public var selectedJourneyID: UUID? { selection?.selectedJourneyID }

    public init(store: AtlasStore, selection: (any AtlasSelectionDelegate)? = nil, session: AtlasSessionContext? = nil) {
        self.store = store; self.selection = selection; self.session = session
    }
    func saved() -> some View { SavedScreen() }
    func place(id: String) -> any Coordinatable { PlaceCoordinator(placeID: id, store: store, session: session) }
    func journey(id: UUID) -> any Coordinatable { JourneyCoordinator(journeyID: id, store: store, session: session) }
}

extension SavedCoordinator {
    public func choose(_ id: String) {
        if let selection { selection.openPlace(id) } else { route(to: .place(id: id)) }
    }
    public func showJourney(_ id: UUID) {
        guard store.plan(id) != nil else { return }
        if let selection { selection.openJourney(id) }
        else { popToRoot(); route(to: .journey(id: id)) }
    }
    public func customize(_ view: AnyView) -> some View {
        view.navigationSplitViewColumnWidth(min: 300, ideal: 360, max: 460)
    }
}

private enum SavedCollection: String, CaseIterable { case journeys = "Journeys", places = "Places" }

struct SavedScreen: View {
    @Environment(SavedCoordinator.self) private var coordinator
    @Environment(\.atlasSession) private var session
    @State private var collection: SavedCollection = .journeys
    @State private var initializedCollection = false

    var body: some View {
        ScrollViewReader { proxy in
            List(selection: Binding(
                get: { coordinator.selectedJourneyID?.uuidString ?? coordinator.selectedPlaceID },
                set: { id in
                    guard coordinator.isColumn, let id else { return }
                    if let journeyID = UUID(uuidString: id) { coordinator.showJourney(journeyID) }
                    else { coordinator.choose(id) }
                }
            )) {
                if !coordinator.isColumn { AtlasFeedbackSection() }
                Section {
                    Picker("Collection", selection: $collection) {
                        Text("Journeys").tag(SavedCollection.journeys).accessibilityIdentifier("saved.collection.journeys")
                        Text("Places").tag(SavedCollection.places).accessibilityIdentifier("saved.collection.places")
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("saved.collection")
                }
                if collection == .journeys {
                    Section("Journeys") {
                        if coordinator.store.plans.isEmpty {
                            ContentUnavailableView("No journeys", systemImage: "suitcase.rolling", description: Text("Open a place in Discover and choose Plan a journey."))
                        }
                        ForEach(coordinator.store.plans) { plan in
                            Button { coordinator.showJourney(plan.id) } label: { JourneyRow(plan: plan) }
                                .buttonStyle(.plain)
                                .tag(plan.id.uuidString).id(plan.id.uuidString)
                                .accessibilityIdentifier("journey.\(plan.placeID)")
                        }
                    }
                } else {
                    Section("Places") {
                        if coordinator.store.savedPlaces.isEmpty {
                            ContentUnavailableView("No saved places", systemImage: "bookmark", description: Text("Use the bookmark on a place in Discover to save it here."))
                        }
                        ForEach(coordinator.store.savedPlaces) { place in
                            Button { coordinator.choose(place.id) } label: { PlaceRow(place: place) }
                                .buttonStyle(.plain)
                                .tag(place.id).id(place.id)
                                .accessibilityIdentifier("place.\(place.id)")
                        }
                    }
                }
            }
            .onChange(of: coordinator.selectedJourneyID) { _, id in
                if let id { collection = .journeys; proxy.scrollTo(id.uuidString) }
            }
            .onChange(of: session?.message?.id) { _, id in
                if !coordinator.isColumn, id != nil { proxy.scrollTo("atlas.feedback", anchor: .top) }
            }
        }
        .onAppear {
            guard !initializedCollection else { return }
            initializedCollection = true
            collection = coordinator.store.plans.isEmpty ? .places : .journeys
        }
        .onChange(of: coordinator.store.plans) { old, new in
            if old.isEmpty, !new.isEmpty { collection = .journeys }
        }
        .navigationTitle("Saved")
    }
}

private struct JourneyRow: View {
    let plan: TripPlan
    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 4) {
                Text(PlaceCatalog.place(plan.placeID)?.name ?? "Journey").font(.headline)
                Text("\(plan.days) \(plan.days == 1 ? "day" : "days") · \(plan.pace.rawValue)")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
        } icon: {
            Image(systemName: "suitcase.rolling").foregroundStyle(.secondary)
        }
        .padding(.vertical, 4).contentShape(.rect)
    }
}
