import Testing
import Scaffolding
import ScaffoldingTesting
@testable import Checklist

/// The playground's own flow: the push and pop family it exists to show.
@MainActor
@Suite("Playground flow")
struct PlaygroundFlowTests {
    private func makeFlow() -> PlaygroundCoordinator {
        PlaygroundCoordinator().activated()
    }

    @Test("pushing chains, because the policy is .always")
    func pushChains() {
        let flow = makeFlow()

        flow.push()
        flow.push()

        #expect(flow.depth == 2)
        #expect(flow.count(of: .playground) == 2)
    }

    @Test("replaceLast swaps the top screen so back skips it")
    func replaceTop() {
        let flow = makeFlow()
        flow.push()

        flow.replaceTop()

        #expect(flow.depth == 1)          // replaced, not stacked
        flow.pop()
        #expect(flow.depth == 0)
    }

    @Test("pop and pop(n) walk the stack back down")
    func popFamily() {
        let flow = makeFlow()
        for _ in 0..<4 { flow.push() }
        #expect(flow.depth == 4)

        flow.pop()
        #expect(flow.depth == 3)
        flow.pop(2)
        #expect(flow.depth == 1)
        flow.popToRoot()
        #expect(flow.depth == 0)
        #expect(flow.topDestination == .playground)
    }

    @Test("meta-based pops match the root when it shares the case")
    func metaPopsMatchTheRoot() {
        let flow = makeFlow()
        for _ in 0..<3 { flow.push() }

        // The root is `.playground` too, and popToFirst/popToLast compare
        // cases — so the first match *is* the root and both behave like
        // popToRoot here. On a stack of mixed cases they stop mid-stack.
        flow.popToFirst(.playground)
        #expect(flow.depth == 0)

        for _ in 0..<3 { flow.push() }
        flow.popToLast(.playground)
        #expect(flow.depth == 0)
    }
}
