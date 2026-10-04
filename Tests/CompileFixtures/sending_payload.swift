import SwiftUI
import Scaffolding

@MainActor @Observable @Scaffoldable(codable: true)
public final class SendingPayloadCoordinator: FlowCoordinatable {
    public var stack = FlowStack<SendingPayloadCoordinator>(root: .home)
    func home() -> some View { EmptyView() }
    func detail(value: sending String = "default") -> some View { Text(value) }
    nonisolated func external(value: sending String) -> some View { Text(value) }
}

@MainActor func checkSendingPayload() {
    let flow = SendingPayloadCoordinator()
    flow.route(to: .detail())
    flow.route(to: .detail(value: "explicit"))
    flow.route(to: .external(value: "safe across isolation"))
}
