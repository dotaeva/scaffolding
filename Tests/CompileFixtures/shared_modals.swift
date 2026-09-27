import SwiftUI
import Scaffolding

@MainActor func genericNavigation<C: Coordinatable, Child: Coordinatable>(_ coordinator: C, route: C.Destinations, child: Child.Type) async {
    coordinator.present(route)
    _ = coordinator.isPresentingModal
    coordinator.dismissPresentedModal()
    let (child, result) = coordinator.present(route, expecting: child, awaiting: String.self)
    child?.dismissCoordinator(returning: "result")
    coordinator.dismissAllModals()
    _ = await result()
    _ = await coordinator.present(route, policy: .distinct, awaiting: String.self)
}
