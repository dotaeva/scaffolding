import SwiftUI
import Scaffolding

/// Small presented flow that exists to return a value. Being a flow, it can
/// push its own screens inside the sheet (Custom amount) without touching
/// the presenting stack.
@MainActor
@Observable
@Scaffoldable(codable: true)
final class LimitCoordinator: @MainActor FlowCoordinatable {
    var stack = FlowStack<LimitCoordinator>(root: .presets)

    func presets() -> some View { LimitPresetsScreen() }
    func custom() -> some View { CustomLimitScreen() }

    func openCustom() {
        route(to: .custom)
    }

    /// Deliver the result and close — the presenter's `awaiting:` call
    /// resumes with the value.
    func finish(_ amount: Decimal) {
        dismissCoordinator(returning: amount)
    }

    /// Plain dismissal (also a swipe-down) resumes the presenter with nil.
    func cancel() {
        dismissCoordinator()
    }
}
