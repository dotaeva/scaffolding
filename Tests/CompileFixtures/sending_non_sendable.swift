import SwiftUI
import Scaffolding

final class MutableRoutePayload { var value = 0 }

@MainActor @Observable @Scaffoldable
final class UnsafeSendingCoordinator: FlowCoordinatable {
    var stack = FlowStack<UnsafeSendingCoordinator>(root: .home)
    func home() -> some View { EmptyView() }
    // This method is allowed to send its parameter away. The generated bridge
    // must not bypass Swift's check when the route retains this mutable object.
    nonisolated func detail(value: sending MutableRoutePayload) -> some View {
        Task.detached { value.value += 1 }
        return EmptyView()
    }
}
