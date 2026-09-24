import SwiftUI
import Scaffolding
import AtlasDomain
import AtlasDesign
import AtlasPlaces

@MainActor @Observable @Scaffoldable(codable: true)
public final class ExploreCoordinator: FlowCoordinatable {
    public var stack = FlowStack<ExploreCoordinator>(root: .discover)
    public let store: AtlasStore
    public let session: AtlasSessionContext?
    public var isColumn: Bool { selection != nil }
    public var selectedPlaceID: String? { selection?.selectedPlaceID }
    private weak var selection: (any AtlasSelectionDelegate)?

    public init(store: AtlasStore, selection: (any AtlasSelectionDelegate)? = nil, session: AtlasSessionContext? = nil) {
        self.store = store; self.selection = selection; self.session = session
    }

    func discover() -> some View { DiscoverScreen() }
    func place(id: String) -> any Coordinatable { PlaceCoordinator(placeID: id, store: store, session: session) }

    public func choose(_ id: String) {
        guard PlaceCatalog.place(id) != nil else { return }
        if let selection { selection.openPlace(id) } else { route(to: .place(id: id)) }
    }
}

extension ExploreCoordinator {
    public func customize(_ view: AnyView) -> some View {
        view.navigationSplitViewColumnWidth(min: 300, ideal: 360, max: 460)
    }
}

struct DiscoverScreen: View {
    @Environment(ExploreCoordinator.self) private var coordinator
    @Environment(\.atlasSession) private var session
    var body: some View {
        ScrollViewReader { proxy in
            List(selection: Binding(
                get: { coordinator.selectedPlaceID },
                set: { if coordinator.isColumn, let id = $0 { coordinator.choose(id) } }
            )) {
                if !coordinator.isColumn { AtlasFeedbackSection() }
                ForEach(PlaceCatalog.all) { place in
                    Button { coordinator.choose(place.id) } label: { PlaceRow(place: place) }
                        .buttonStyle(.plain)
                        .tag(place.id)
                        .id(place.id)
                        .accessibilityIdentifier("place.\(place.id)")
                }
            }
            .onChange(of: session?.message?.id) { _, id in
                if !coordinator.isColumn, id != nil { proxy.scrollTo("atlas.feedback", anchor: .top) }
            }
            .onChange(of: coordinator.selectedPlaceID, initial: true) { _, id in
                if let id { proxy.scrollTo(id) }
            }
        }
        .navigationTitle("Discover")
    }
}
