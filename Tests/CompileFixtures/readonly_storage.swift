import SwiftUI
import Scaffolding
@MainActor func invalid<C: FlowCoordinatable>(_ coordinator: C) {
    coordinator.stack.destinations.removeAll()
}
