import SwiftUI
import Scaffolding

@Scaffoldable(codable: true) @Observable
final class PlanetsCoordinator: @MainActor FlowCoordinatable {
    var stack = FlowStack<PlanetsCoordinator>(root: .planets)

    func planets() -> some View { PlanetsView() }

    // ✅ A Codable payload — the compiler enforces this at enum synthesis.
    //    Prefer stable identifiers over whole model objects: an id survives
    //    an app update, a struct's stored shape may not.
    func detail(name: String) -> some View { DetailView(name: name) }

    // ❌ A closure payload can never be Codable. Routes like this belong on
    //    a coordinator that does not opt in — or use the `awaiting:` result
    //    pattern instead of a callback.
    //
    // func picker(onPick: @escaping @MainActor (String) -> Void) -> any Coordinatable {
    //     PlanetPickerCoordinator(onPick: onPick)
    // }
}
