import SwiftUI
import Observation
import Scaffolding

@MainActor @Observable @Scaffoldable(codable: true)
final class AvailabilityCoordinator: FlowCoordinatable {
    var stack = FlowStack<AvailabilityCoordinator>(root: .home)
    func home() -> some View { EmptyView() }
    @available(macOS 27, iOS 27, tvOS 27, watchOS 27, *)
    func future() -> some View { EmptyView() }
    @available(macOS, introduced: 27)
    func introduced() -> some View { EmptyView() }
}

@MainActor func checkAvailability(_ coordinator: AvailabilityCoordinator) {
    if #available(macOS 27, iOS 27, tvOS 27, watchOS 27, *) {
        coordinator.route(to: .future)
    }
}

@MainActor @Observable @Scaffoldable(codable: true)
public final class PayloadAvailabilityCoordinator: FlowCoordinatable {
    public var stack = FlowStack<PayloadAvailabilityCoordinator>(root: .home)
    public init() {}
    func home() -> some View { EmptyView() }
    @available(macOS 99, iOS 99, tvOS 99, watchOS 99, *)
    func future(id: Int) -> some View { Text("\(id)") }
    @available(macOS, introduced: 99)
    func introduced(id: Int) -> some View { Text("\(id)") }
}

@MainActor func payloadAvailability() {
    // Payload types are available at the deployment floor. Construction is
    // legal; navigation checks isAvailable before evaluating the factory.
    let owner = PayloadAvailabilityCoordinator()
    owner.present(.future(id: 42))
}
