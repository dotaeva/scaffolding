import SwiftUI
import Scaffolding

@MainActor func legacy<C: Coordinatable>(_ coordinator: C, route: C.Destinations) {
    coordinator.present(route, as: .sheet(
        detents: [.medium, .large],
        dragIndicator: .visible,
        interactiveDismissDisabled: true
    ))
}
