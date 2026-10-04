import SwiftUI
import Scaffolding

@MainActor @Observable @Scaffoldable
public final class ConditionalAliasCoordinator: FlowCoordinatable {
    #if os(macOS)
    public typealias Handler = () -> Int
    #elseif os(iOS)
    public typealias Handler = @MainActor () -> Int
    #else
    #if DEBUG
    public typealias Handler = (() -> Int)
    #else
    public typealias Handler = () -> Int
    #endif
    #endif
    public typealias Callback = Handler

    #if os(iOS)
    public typealias Payload = () -> Int
    #else
    public typealias Payload = Int
    #endif

    public var stack = FlowStack<ConditionalAliasCoordinator>(root: .home)
    func home() -> some View { EmptyView() }
    func detail(callback: Callback = { 1 }) -> some View { EmptyView() }
    func record(id: Int = 1, payload: Payload) -> some View { EmptyView() }
}

@MainActor func checkConditionalAliases() {
    let flow = ConditionalAliasCoordinator()
    flow.route(to: .detail())
    #if os(iOS)
    flow.route(to: .record(payload: { 42 }))
    #else
    flow.route(to: .record(payload: 42))
    #endif
}
