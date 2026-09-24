import SwiftUI
import Scaffolding
import AtlasDomain
import AtlasDesign

/// A transient form with a typed result. The caller owns the completed plan.
@MainActor @Observable @Scaffoldable
public final class PlannerCoordinator: FlowCoordinatable {
    public var stack = FlowStack<PlannerCoordinator>(root: .details)
    public let place: Place
    public let planID: UUID
    public let isEditing: Bool
    public var days = 3
    public var pace: TravelPace = .unhurried

    public init(place: Place, plan: TripPlan? = nil) {
        self.place = place
        self.planID = plan?.id ?? UUID()
        self.isEditing = plan != nil
        self.days = plan?.days ?? 3
        self.pace = plan?.pace ?? .unhurried
    }
    func details() -> some View { PlanDetailsScreen() }
    func review() -> some View { PlanReviewScreen() }

    public func continuePlanning() { route(to: .review, policy: .distinct) }
    public func finish() {
        dismissCoordinator(returning: TripPlan(id: planID, placeID: place.id, days: days, pace: pace))
    }

}

extension PlannerCoordinator {
    public func customize(_ view: AnyView) -> some View {
        #if os(macOS)
        view.frame(minWidth: 400, minHeight: 400)
        #else
        view.presentationDetents([.large])
        #endif
    }
}
