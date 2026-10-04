import SwiftUI
import Testing
import Scaffolding
import ScaffoldingTesting

@MainActor @Observable @Scaffoldable
private final class AvailabilitySeedFlow: FlowCoordinatable {
    var stack: FlowStack<AvailabilitySeedFlow>
    var builtIDs: [Int] = []

    init(pushing path: [Destinations]) {
        stack = .init(root: .home, pushing: path)
    }

    func home() -> some View { EmptyView() }
    func detail(id: Int) -> some View {
        builtIDs.append(id)
        return EmptyView()
    }
    @available(macOS 99, iOS 99, tvOS 99, watchOS 99, macCatalyst 99, *)
    func future(id: Int) -> some View {
        builtIDs.append(id)
        return EmptyView()
    }
}

@MainActor @Suite("Seeded route availability")
struct ReviewAvailabilityTests {
    @Test func unavailablePushesAreSkippedWithoutReorderingAvailableRoutes() {
        let flow = AvailabilitySeedFlow(pushing: [
            .future(id: 99), .detail(id: 1), .future(id: 100), .detail(id: 2)
        ]).activated()
        #expect(flow.depth == 2)
        #expect(flow.builtIDs == [1, 2])
        #expect(flow.count(of: .future) == 0)
        #expect(flow.topDestination == .detail)

        _ = flow.activated()
        #expect(flow.builtIDs == [1, 2])
    }

    @Test func entirelyUnavailablePathKeepsTheRootAndAllowsLaterNavigation() {
        let flow = AvailabilitySeedFlow(pushing: [.future(id: 99)]).activated()
        #expect(flow.depth == 0)
        #expect(flow.topDestination == .home)
        #expect(flow.builtIDs.isEmpty)
        flow.route(to: .future(id: 100))
        #expect(flow.depth == 0)
        flow.route(to: .detail(id: 1))
        #expect(flow.depth == 1)
        #expect(flow.builtIDs == [1])
    }
}
