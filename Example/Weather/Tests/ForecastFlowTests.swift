import Testing
import Scaffolding
import ScaffoldingTesting
@testable import Weather

/// The push/pop workhorse: policies, replaceLast, every pop, awaitable
/// navigation, flow-level setRoot, and the seeded initializer.
@MainActor
@Suite("Forecast flow")
struct ForecastFlowTests {
    private func makeFlow() -> ForecastCoordinator {
        ForecastCoordinator(location: .prague, store: WeatherStore()).activated()
    }

    @Test("open is guarded, chaining is not")
    func policies() {
        let flow = makeFlow()
        let day = flow.days[1]

        flow.open(day)
        flow.open(day)                    // .distinct — skipped
        #expect(flow.count(of: .day) == 1)

        flow.openNext(after: day)         // .always — chains
        flow.openNext(after: flow.days[2])
        #expect(flow.count(of: .day) == 3)
        #expect(flow.depth == 3)
    }

    @Test("replaceLast swaps the top so back skips it")
    func replaceLast() {
        let flow = makeFlow()
        flow.open(flow.days[1])

        flow.skipToNext(after: flow.days[1])

        #expect(flow.depth == 1)          // replaced, not stacked
        flow.pop()
        #expect(flow.depth == 0)          // back skipped day 1
    }

    @Test("every pop variant behaves as documented")
    func popVariants() {
        let flow = makeFlow()
        for index in 1...4 { flow.openNext(after: flow.days[index - 1]) }
        #expect(flow.depth == 4)
        flow.pop(2)
        #expect(flow.depth == 2)
        flow.popToFirst(.day)
        #expect(flow.depth == 1)
        flow.popToRoot()
        #expect(flow.depth == 0)
    }

    @Test("chooseDay suspends in routeAndWait until the picker pops")
    func chooseDayAwaits() async {
        let flow = makeFlow()

        flow.chooseDay()
        await waitUntil { flow.topDestination == .dayPicker }

        flow.pickedDay = flow.days[4]
        flow.pop()
        await waitUntil { flow.count(of: .day) == 1 }

        #expect(flow.topDestination == .day)
    }

    @Test("acknowledging the alert continues into the radar")
    func alertThenRadar() async {
        let flow = makeFlow()

        flow.reviewAlertThenRadar()
        await waitUntil { flow.isPresentingModal }

        flow.dismissModal()               // stands in for Acknowledge
        await waitUntil { flow.count(of: .radar) == 1 }
        #expect(flow.isPresentingModal)
    }

    @Test("switching location is a flow-level setRoot")
    func switchLocation() {
        let flow = makeFlow()
        flow.open(flow.days[1])

        flow.switchLocation(.tokyo)

        #expect(flow.depth == 0)          // stack cleared with the root
        #expect(flow.location == .tokyo)
    }

    @Test("the seeded initializer starts mid-flow")
    func seededStart() {
        let day = ForecastEngine.tenDays(for: .oslo)[3]
        let flow = ForecastCoordinator(location: .oslo, store: WeatherStore(), startingAt: day)

        #expect(flow.activated().depth == 1)
        #expect(flow.topDestination == .day)
    }
}
