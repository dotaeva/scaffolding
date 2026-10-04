import SwiftUI
import Testing
import Scaffolding

@MainActor @Observable @Scaffoldable(codable: true)
private final class SendingRouteFlow: FlowCoordinatable {
    var stack = FlowStack<SendingRouteFlow>(root: .home)
    var received: [String] = []
    func home() -> some View { EmptyView() }
    func detail(value: sending String = "default") -> some View {
        received.append(value)
        return Text(value)
    }
    func child(value: sending String) -> any Coordinatable {
        SendingChildFlow(title: value)
    }
}

@MainActor @Observable @Scaffoldable
private final class SendingChildFlow: FlowCoordinatable {
    let title: String
    var stack = FlowStack<SendingChildFlow>(root: .home)
    init(title: String) { self.title = title }
    func home() -> some View { Text(title) }
}

@MainActor @Suite("Sending route payloads")
struct SendingRouteTests {
    @Test func explicitAndDefaultValuesCanBeRoutedRepeatedly() {
        let flow = SendingRouteFlow()
        let route = SendingRouteFlow.Destinations.detail(value: "explicit")
        flow.route(to: route)
        flow.route(to: route)
        flow.route(to: .detail())
        #expect(flow.received == ["explicit", "explicit", "default"])
        #expect(flow.depth == 3)
    }

    @Test func sendingPayloadReachesADeferredChildFactory() throws {
        let flow = SendingRouteFlow()
        let child = try #require(flow.route(to: .child(value: "child"), expecting: SendingChildFlow.self))
        #expect(child.title == "child")
    }

    @Test func sendingPayloadCanBeCapturedAndRestored() throws {
        let flow = SendingRouteFlow()
        flow.route(to: .detail(value: "restored"))
        let data = try flow.captureNavigationState()
        let restored = SendingRouteFlow()
        try restored.restoreNavigationState(from: data, mode: .replace)
        #expect(restored.received == ["restored"])
        #expect(restored.topDestination == .detail)
    }
}
