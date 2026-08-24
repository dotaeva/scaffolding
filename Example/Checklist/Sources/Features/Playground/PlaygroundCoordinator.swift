import SwiftUI
import Scaffolding

/// A live console for the whole navigation API: a tab on iPhone, a sidebar
/// row on iPad and Mac. Push, replace, pop, present, await a result, swap
/// the root — every button is one call, and the readouts update as it lands.
@MainActor
@Observable
@Scaffoldable(codable: true)
final class PlaygroundCoordinator: @MainActor FlowCoordinatable {
    var stack = FlowStack<PlaygroundCoordinator>(root: .playground)

    /// What the last awaited navigation handed back.
    var lastResult: String?
    /// How many pushed destinations have reported their dismissal.
    var dismissals = 0

    // MARK: Routes

    func playground() -> some View { PlaygroundView() }

    /// A distinct case, so the meta-based pops have something to aim at
    /// that is not the root.
    func leaf(label: String) -> some View { PlaygroundLeafView(label: label) }

    /// A child *coordinator* pushed onto this stack — it can dismiss
    /// itself and read its ancestors.
    func child() -> any Coordinatable { PlaygroundChildCoordinator() }

    /// View-only modals: no coordinator inside, so the presenter closes them.
    func sheet() -> some View { PlaygroundModalView(title: "Sheet") }
    func cover() -> some View { PlaygroundModalView(title: "Full-screen cover") }

    /// A sub-flow whose whole job is returning a value.
    func picker() -> any Coordinatable { PlaygroundPickerCoordinator() }
}
