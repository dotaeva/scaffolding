import SwiftUI
import Scaffolding
@MainActor func legacy<C: FlowCoordinatable>(_ coordinator: C, route: C.Destinations) {
    coordinator.replaceLast(with: route)
}
