import SwiftUI
import Scaffolding
@MainActor func invalid<C: FlowCoordinatable>(_ coordinator: C) {
    coordinator.anyStack.destinations.removeAll()
}
