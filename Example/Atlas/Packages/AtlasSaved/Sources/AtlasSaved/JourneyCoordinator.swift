import SwiftUI
import Scaffolding
import AtlasDomain
import AtlasDesign
import AtlasPlaces
import AtlasPlanner

/// A saved journey is addressed by identity, so editing never creates a duplicate.
@MainActor @Observable @Scaffoldable(codable: true)
public final class JourneyCoordinator: FlowCoordinatable {
    public var stack = FlowStack<JourneyCoordinator>(root: .summary)
    public let journeyID: UUID
    public let store: AtlasStore
    public let session: AtlasSessionContext?
    public private(set) var isEditing = false
    private weak var selection: (any AtlasSelectionDelegate)?
    public var plan: TripPlan? { store.plan(journeyID) }

    public init(journeyID: UUID, store: AtlasStore, selection: (any AtlasSelectionDelegate)? = nil, session: AtlasSessionContext? = nil) {
        self.journeyID = journeyID; self.store = store; self.selection = selection; self.session = session
    }
    func summary() -> some View { JourneyScreen() }
    func planner() -> any Coordinatable {
        PlannerCoordinator(place: PlaceCatalog.place(plan?.placeID ?? "") ?? PlaceCatalog.all[0], plan: plan)
    }
    func place(id: String) -> any Coordinatable { PlaceCoordinator(placeID: id, store: store, session: session) }
}

extension JourneyCoordinator {
    public func edit() {
        guard plan != nil, !isEditing, !isPresentingModal else { return }
        isEditing = true
        Task { @MainActor [weak self] in
            guard let self else { return }
            defer { isEditing = false }
            if let updated = await present(.planner, awaiting: TripPlan.self), store.update(updated) {
                session?.show("Journey updated.")
            }
        }
    }
    public func remove() {
        guard let plan else { return }
        store.remove(plan.id)
        // Split columns are structural; their owner replaces them.
        if let selection { selection.clearJourney(journeyID) } else { dismissCoordinator() }
        session?.show("Journey removed.", action: .undoRemoval(plan))
    }
}

private struct JourneyScreen: View {
    @Environment(JourneyCoordinator.self) private var coordinator
    var body: some View {
        AtlasForm {
            if let plan = coordinator.plan, let place = PlaceCatalog.place(plan.placeID) {
                Section("Journey details") {
                    LabeledContent("Place", value: place.name)
                    LabeledContent("Time away", value: "\(plan.days) \(plan.days == 1 ? "day" : "days")")
                    LabeledContent("Pace", value: plan.pace.rawValue)
                }
                Section {
                    Button("Edit journey", systemImage: "slider.horizontal.3") { coordinator.edit() }
                        .accessibilityIdentifier("journey.edit")
                    Button("Explore \(place.name)", systemImage: "map") { coordinator.route(to: .place(id: place.id)) }
                        .accessibilityIdentifier("journey.place")
                    Button("Remove journey", role: .destructive) { coordinator.remove() }
                        .accessibilityIdentifier("journey.remove")
                } footer: {
                    Text("Saved on this device. No bookings or reservations.")
                }
            } else {
                ContentUnavailableView("Journey unavailable", systemImage: "suitcase", description: Text("This journey may have been removed in another window."))
            }
        }
        .navigationTitle("Your journey").modifier(InlineNavigationTitle())
    }
}
