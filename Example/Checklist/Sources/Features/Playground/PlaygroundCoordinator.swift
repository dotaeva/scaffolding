import SwiftUI
import Scaffolding

/// The navigation playground: a first-class destination (a tab on iPhone, a
/// sidebar row on iPad and Mac) rather than something buried in Settings.
///
/// Its own flow, so the push/pop buttons have a real stack to work on.
@MainActor
@Observable
@Scaffoldable(codable: true)
final class PlaygroundCoordinator: @MainActor FlowCoordinatable {
    var stack = FlowStack<PlaygroundCoordinator>(root: .playground)

    // MARK: Routes

    func playground() -> some View { PlaygroundView() }
}

// MARK: - Navigation

extension PlaygroundCoordinator {
    /// `.always` on purpose: the stack is meant to grow so the pop family
    /// has something to take apart.
    func push() { route(to: .playground) }

    func replaceTop() { replaceLast(with: .playground) }
}
