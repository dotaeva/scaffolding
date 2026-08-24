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
    // The route table: one line per destination, with the bodies in
    // PlaygroundCoordinator+Factory.swift. These declarations have to stay in the class
    // body — @Scaffoldable scans only the class declaration, so a route
    // moved to an extension is silently untracked.

    func playground() -> some View { makePlayground() }

    func leaf(label: String) -> some View { makeLeaf(label: label) }

    func child() -> any Coordinatable { makeChild() }

    func sheet() -> some View { makeSheet() }
    func cover() -> some View { makeCover() }

    func picker() -> any Coordinatable { makePicker() }
}
