import SwiftUI
import Testing
import Scaffolding

@MainActor @Observable @Scaffoldable
public final class PayloadReviewFlow: FlowCoordinatable {
    public typealias Handler = @MainActor () -> Int
    public typealias AliasedHandler = Handler
    public typealias Meta = Int
    public typealias Owner = String

    public var stack = FlowStack<PayloadReviewFlow>(root: .home)
    func home() -> some View { EmptyView() }
    func aliased(callback: AliasedHandler = { 7 }) -> some View { EmptyView() }
    func qualified(id: Int = 1, callback: PayloadReviewFlow.Handler) -> some View { EmptyView() }
    func parenthesized(callback: ((@MainActor () -> Int)) = { 8 }) -> some View { EmptyView() }
    func optional(callback: Handler? = nil) -> some View { EmptyView() }
    func record(id: Meta, owner: Owner, nested: [Meta]) -> some View { EmptyView() }
    func defaultRecord(id: Meta = Meta(42), owner: String = Owner("owner")) -> some View { EmptyView() }
    func source(line: @autoclosure () -> Int = #line, file: @autoclosure () -> String = #fileID) -> some View { EmptyView() }
}

@MainActor @Observable @Scaffoldable
final class InternalSourceReviewFlow: FlowCoordinatable {
    var stack = FlowStack<InternalSourceReviewFlow>(root: .source())
    func source(line: @autoclosure () -> Int = #line) -> some View { EmptyView() }
}

@MainActor @Suite("Macro payloads")
struct MacroPayloadTests {
    @Test func closureAliasesAndParenthesesKeepTheirValues() {
        guard case .aliased(let defaultHandler) = PayloadReviewFlow.Destinations.aliased(),
              case .qualified(let id, let suppliedHandler) = PayloadReviewFlow.Destinations.qualified(callback: { 9 }),
              case .parenthesized(let parenthesized) = PayloadReviewFlow.Destinations.parenthesized(),
              case .optional(let optional) = PayloadReviewFlow.Destinations.optional() else {
            Issue.record("Unexpected route")
            return
        }
        #expect(defaultHandler() == 7)
        #expect(id == 1)
        #expect(suppliedHandler() == 9)
        #expect(parenthesized() == 8)
        #expect(optional == nil)
    }

    @Test func payloadNamesKeepTheirOriginalTypes() {
        let route = PayloadReviewFlow.Destinations.record(id: 42, owner: "owner", nested: [1, 2])
        guard case .record(let id, let owner, let nested) = route else {
            Issue.record("Unexpected route")
            return
        }
        #expect(id == 42)
        #expect(owner == "owner")
        #expect(nested == [1, 2])
        guard case .defaultRecord(let defaultID, let defaultOwner) = PayloadReviewFlow.Destinations.defaultRecord() else {
            Issue.record("Unexpected route")
            return
        }
        #expect(defaultID == 42)
        #expect(defaultOwner == "owner")
        // Resolving also type-checks the generated bridge to the route method.
        let coordinator = PayloadReviewFlow()
        coordinator.route(to: route)
        #expect(coordinator.topDestination == .record)
    }

    @Test func autoclosureSourceDefaultsUseTheCallSite() {
        let expectedLine = #line + 1
        let route = PayloadReviewFlow.Destinations.source()
        guard case .source(let line, let file) = route else {
            Issue.record("Unexpected route")
            return
        }
        #expect(line() == expectedLine)
        #expect(file() == #fileID)

        let expectedPartialLine = #line + 1
        let partial = PayloadReviewFlow.Destinations.source(file: { "supplied" })
        guard case .source(let partialLine, let suppliedFile) = partial else {
            Issue.record("Unexpected route")
            return
        }
        #expect(partialLine() == expectedPartialLine)
        #expect(suppliedFile() == "supplied")

        let other = PayloadReviewFlow.Destinations.source(line: { 123 })
        guard case .source(let suppliedLine, let defaultFile) = other else {
            Issue.record("Unexpected route")
            return
        }
        #expect(suppliedLine() == 123)
        #expect(defaultFile() == #fileID)

        let expectedInternalLine = #line + 1
        let internalRoute = InternalSourceReviewFlow.Destinations.source()
        guard case .source(let internalLine) = internalRoute else {
            Issue.record("Unexpected route")
            return
        }
        #expect(internalLine() == expectedInternalLine)
    }
}
