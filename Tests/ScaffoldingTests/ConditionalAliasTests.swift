import SwiftUI
import Testing
import Scaffolding

private typealias PlatformPayload = Int

@MainActor @Observable @Scaffoldable
private final class ConditionalAliasFlow: FlowCoordinatable {
    #if os(macOS)
    typealias Handler = () -> Int
    #elseif os(iOS)
    typealias Handler = @MainActor () -> Int
    #else
    #if DEBUG
    typealias Handler = (() -> Int)
    #else
    typealias Handler = () -> Int
    #endif
    #endif
    typealias Callback = Handler

    var stack = FlowStack<ConditionalAliasFlow>(root: .home)
    func home() -> some View { EmptyView() }
    func detail(callback: Callback = { 1 }) -> some View { EmptyView() }
    func required(id: Int = 1, callback: ConditionalAliasFlow.Handler) -> some View { EmptyView() }
}

@MainActor @Observable @Scaffoldable
private final class ConditionalValueFlow: FlowCoordinatable {
    #if os(iOS)
    typealias Payload = () -> Int
    #else
    typealias Payload = Int
    #endif

    var stack = FlowStack<ConditionalValueFlow>(root: .home)
    func home() -> some View { EmptyView() }
    func detail(id: Int = 1, payload: Payload) -> some View { EmptyView() }
}

@MainActor @Observable @Scaffoldable
private final class OuterAliasFlow: FlowCoordinatable {
    #if os(iOS)
    typealias PlatformPayload = () -> Int
    #endif
    var stack = FlowStack<OuterAliasFlow>(root: .home)
    func home() -> some View { EmptyView() }
    func detail(id: Int = 1, payload: PlatformPayload) -> some View { EmptyView() }
}

@MainActor @Suite("Conditional route aliases")
struct ConditionalAliasTests {
    @Test func defaultAndRequiredClosuresSurviveTheGeneratedFactory() {
        let defaultRoute = ConditionalAliasFlow.Destinations.detail()
        guard case .detail(let callback) = defaultRoute,
              case .required(let id, let required) = ConditionalAliasFlow.Destinations.required(callback: { 2 }) else {
            Issue.record("Unexpected route")
            return
        }
        #expect(callback() == 1)
        #expect(id == 1)
        #expect(required() == 2)
        let flow = ConditionalAliasFlow()
        flow.route(to: defaultRoute)
        #expect(flow.topDestination == .detail)
    }

    @Test func anAliasCanBeAClosureOnOnePlatformAndAValueOnAnother() {
        #if os(iOS)
        let route = ConditionalValueFlow.Destinations.detail(payload: { 42 })
        #else
        let route = ConditionalValueFlow.Destinations.detail(payload: 42)
        #endif
        guard case .detail(let id, let payload) = route else {
            Issue.record("Unexpected route")
            return
        }
        #expect(id == 1)
        #if os(iOS)
        #expect(payload() == 42)
        #else
        #expect(payload == 42)
        #endif
    }

    @Test func aMissingConditionalAliasStillAllowsOuterScopeLookup() {
        #if os(iOS)
        let route = OuterAliasFlow.Destinations.detail(payload: { 42 })
        #else
        let route = OuterAliasFlow.Destinations.detail(payload: 42)
        #endif
        let flow = OuterAliasFlow()
        flow.route(to: route)
        #expect(flow.topDestination == .detail)
    }
}
