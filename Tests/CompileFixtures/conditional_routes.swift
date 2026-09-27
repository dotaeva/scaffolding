import SwiftUI
import Observation
import Scaffolding

@MainActor @Observable @Scaffoldable(codable: true)
final class ConditionalCoordinator: FlowCoordinatable {
    var stack = FlowStack<ConditionalCoordinator>(root: .home)
    func home() -> some View { EmptyView() }
#if os(macOS)
    func platform(_ number: Int) -> some View { Text("Mac \(number)") }
#elseif os(iOS)
    func platform(_ number: Int) -> some View { Text("iOS \(number)") }
#else
    func platform(_ number: Int) -> some View { Text("Other \(number)") }
#endif
#if os(macOS) || os(iOS)
#if DEBUG
    func nested() -> some View { Text("Debug") }
#else
    func nested() -> some View { Text("Release") }
#endif
#endif
}

@MainActor func checkConditional(_ coordinator: ConditionalCoordinator) {
    coordinator.route(to: .platform(42))
#if os(macOS) || os(iOS)
    coordinator.route(to: .nested)
#endif
}
