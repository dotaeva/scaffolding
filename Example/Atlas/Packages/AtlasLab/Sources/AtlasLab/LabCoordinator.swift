import SwiftUI
import Scaffolding
import AtlasDomain
import AtlasDesign
import AtlasPlanner

@MainActor @Observable @Scaffoldable(codable: true)
public final class LabCoordinator: FlowCoordinatable {
    public var stack = FlowStack<LabCoordinator>(root: .dashboard)
    public private(set) var lastResult = "No choice yet"
    public private(set) var isChoosing = false
    public private(set) var isPlanning = false
    public private(set) var navigationOutcome = ""
    public let context: AtlasSessionContext?
    public weak var session: (any AtlasSessionActions)?

    public init(session: (any AtlasSessionActions)?, context: AtlasSessionContext? = nil) { self.session = session; self.context = context }
    func dashboard() -> some View { LabScreen() }
    func step(number: Int) -> some View { LabStepScreen(number: number) }
    func choice() -> any Coordinatable { ChoiceCoordinator() }

    func planner() -> any Coordinatable { PlannerCoordinator(place: PlaceCatalog.all[0]) }

    public func pushStep(_ number: Int) {
        let alreadyPresent = isInStack(.step)
        route(to: .step(number: number), policy: .distinct)
        navigationOutcome = alreadyPresent ? "Already on a chapter. The distinct policy kept the stack unchanged." : "Pushed chapter \(number)."
    }
    public func replaceStep(_ number: Int) {
        replaceLast(with: .step(number: number))
        navigationOutcome = "Replaced the chapter. Stack depth stayed the same."
    }
    public func planFullScreen() {
        guard !isPlanning, !isPresentingModal else { return }
        isPlanning = true
        Task { @MainActor [weak self] in
            guard let self else { return }
            defer { isPlanning = false }
            if let plan = await present(.planner, as: .fullScreenCover, awaiting: TripPlan.self) {
                context?.store.add(plan)
                context?.show("Journey saved to your collection.", action: .journey(plan.id))
            }
        }
    }
    public func choose() {
        guard !isChoosing, !isPresentingModal else { return }
        isChoosing = true
        Task { @MainActor [weak self] in
            guard let self else { return }
            defer { isChoosing = false }
            let choice = await present(.choice, awaiting: String.self)
            lastResult = choice.map { "You chose \($0)." } ?? "Closed without a result."
        }
    }
}

@MainActor @Observable @Scaffoldable
final class ChoiceCoordinator: FlowCoordinatable {
    var stack = FlowStack<ChoiceCoordinator>(root: .choice)
    func choice() -> some View { ChoiceScreen() }
}

private struct ChoiceScreen: View {
    @Environment(ChoiceCoordinator.self) private var coordinator
    var body: some View {
        AtlasForm {
            Section("Choose a destination") {
                Button("Mountains", systemImage: "mountain.2") { coordinator.dismissCoordinator(returning: "mountains") }
                Button("The sea", systemImage: "water.waves") { coordinator.dismissCoordinator(returning: "the sea") }
            }
        }
        .navigationTitle("An awaited choice").modifier(InlineNavigationTitle())
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { coordinator.dismissCoordinator() }.keyboardShortcut(.cancelAction)
            }
        }
        .frame(minWidth: 300, minHeight: 320)
    }
}
