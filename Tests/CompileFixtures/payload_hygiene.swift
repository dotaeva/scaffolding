import SwiftUI
import Scaffolding

public struct Meta: Codable { let id: Int }
public struct Owner: Codable { let name: String }

@MainActor @Observable @Scaffoldable(codable: true)
public final class ExternalPayloadCoordinator: FlowCoordinatable {
    public var stack = FlowStack<ExternalPayloadCoordinator>(root: .home)
    func home() -> some View { EmptyView() }
    func record(meta: Meta, owner: Owner) -> some View { EmptyView() }
    #if os(macOS)
    func conditional(value: Meta) -> some View { EmptyView() }
    #else
    func conditional(value: Owner) -> some View { EmptyView() }
    #endif
}

@MainActor @Observable @Scaffoldable
public final class GenericPayloadCoordinator<Owner>: FlowCoordinatable {
    public var stack = FlowStack<GenericPayloadCoordinator>(root: .home)
    func home() -> some View { EmptyView() }
    func record(value: Owner) -> some View { EmptyView() }
}

@MainActor @Observable @Scaffoldable
public final class ClosurePayloadCoordinator: FlowCoordinatable {
    public typealias Handler = @MainActor () -> Int
    public var stack = FlowStack<ClosurePayloadCoordinator>(root: .home)
    func home() -> some View { EmptyView() }
    func aliased(callback: Handler = { 7 }) -> some View { EmptyView() }
    func parenthesized(callback: (() -> Int) = { 8 }) -> some View { EmptyView() }
    func source(line: @autoclosure () -> Int = #line, file: @autoclosure () -> String = #fileID) -> some View { EmptyView() }
}

@MainActor func checkPayloadHygiene() {
    let external = ExternalPayloadCoordinator()
    external.route(to: .record(meta: Meta(id: 1), owner: Owner(name: "owner")))
    #if os(macOS)
    external.route(to: .conditional(value: Meta(id: 2)))
    #else
    external.route(to: .conditional(value: Owner(name: "other")))
    #endif
    GenericPayloadCoordinator<Int>().route(to: .record(value: 42))
    let closures = ClosurePayloadCoordinator()
    closures.route(to: .aliased())
    closures.route(to: .parenthesized())
    closures.route(to: .source())
    closures.route(to: .source(line: { 42 }))
    closures.route(to: .source(file: { "supplied" }))
}
