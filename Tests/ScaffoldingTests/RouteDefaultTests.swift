import SwiftUI
import Testing
import Scaffolding

@MainActor @Observable @Scaffoldable(codable: true)
public final class DefaultReviewFlow: FlowCoordinatable {
    static var defaultID = 42
    static var evaluations = 0
    public var stack = FlowStack<DefaultReviewFlow>(root: .home)

    func home() -> some View { EmptyView() }
    func detail(id: Int = defaultID) -> some View { Text("\(id)") }
    func labels(a: Int = nextID(), required: String, b: Int = defaultID) -> some View { EmptyView() }
    func positional(_ a: Int = 1, _ b: Int = 2) -> some View { EmptyView() }
    func mixed(_ a: Int = 1, label: String = "default", _ b: Int = 2) -> some View { EmptyView() }
    func source(line: Int = #line, file: String = #fileID) -> some View { EmptyView() }

    static func nextID() -> Int {
        evaluations += 1
        return defaultID
    }
}

@MainActor @Observable @Scaffoldable
public final class ClosureDefaultReviewFlow: FlowCoordinatable {
    public typealias Callback = @MainActor () -> Int
    public var stack = FlowStack<ClosureDefaultReviewFlow>(root: .home)
    func home() -> some View { EmptyView() }
    func handler(id: Int = DefaultReviewFlow.defaultID, callback: @escaping @MainActor () -> Int = { 7 }) -> some View { EmptyView() }
    func autoclosure(value: @autoclosure @MainActor () -> Int = DefaultReviewFlow.defaultID) -> some View { Text("\(value())") }
    func aliasHandler(id: Int = 42, callback: @escaping Callback = { 7 }) -> some View { EmptyView() }
}

@MainActor @Suite("Generated route defaults", .serialized)
struct RouteDefaultTests {
    @Test func isolatedDefaultsAreEvaluatedWhenConstructingTheRoute() throws {
        defer { DefaultReviewFlow.defaultID = 42 }
        DefaultReviewFlow.defaultID = 51
        let first = DefaultReviewFlow.Destinations.detail()
        DefaultReviewFlow.defaultID = 61
        let second = DefaultReviewFlow.Destinations.detail()
        if case .detail(let id) = first { #expect(id == 51) }
        else { Issue.record("Wrong route") }
        if case .detail(let id) = second { #expect(id == 61) }
        else { Issue.record("Wrong route") }
        // Stored payloads and the synthesized Codable representation stay intact.
        let data = try JSONEncoder().encode(first)
        let copy = try JSONDecoder().decode(DefaultReviewFlow.Destinations.self, from: data)
        if case .detail(let id) = copy { #expect(id == 51) }
        else { Issue.record("Wrong decoded route") }
    }

    @Test func labeledDefaultsSupportEveryOmissionWithoutExtraEvaluation() {
        DefaultReviewFlow.evaluations = 0
        let routes: [DefaultReviewFlow.Destinations] = [
            .labels(required: "both"),
            .labels(a: 9, required: "last"),
            .labels(required: "first", b: 8),
            .labels(a: 9, required: "neither", b: 8),
        ]
        let expected = [(42, 42), (9, 42), (42, 8), (9, 8)]
        for (route, values) in zip(routes, expected) {
            guard case .labels(let a, _, let b) = route else { Issue.record("Wrong route"); continue }
            #expect(a == values.0)
            #expect(b == values.1)
        }
        #expect(DefaultReviewFlow.evaluations == 2)
    }

    @Test func unlabeledDefaultsKeepLeftToRightArgumentMatching() {
        let routes: [DefaultReviewFlow.Destinations] = [.positional(), .positional(9), .positional(9, 8)]
        for (route, values) in zip(routes, [(1, 2), (9, 2), (9, 8)]) {
            guard case .positional(let a, let b) = route else { Issue.record("Wrong route"); continue }
            #expect(a == values.0)
            #expect(b == values.1)
        }
        let mixed: [DefaultReviewFlow.Destinations] = [
            .mixed(), .mixed(9), .mixed(label: "x"), .mixed(label: "x", 8),
            .mixed(9, label: "x"), .mixed(9, 8), .mixed(9, label: "x", 8),
        ]
        let expected = [(1, "default", 2), (9, "default", 2), (1, "x", 2), (1, "x", 8),
                        (9, "x", 2), (9, "default", 8), (9, "x", 8)]
        for (route, values) in zip(mixed, expected) {
            guard case .mixed(let a, let label, let b) = route else { Issue.record("Wrong route"); continue }
            #expect(a == values.0)
            #expect(label == values.1)
            #expect(b == values.2)
        }
    }

    @Test func sourceLocationDefaultsReferToTheCaller() {
        let expectedLine = #line + 1
        let route = DefaultReviewFlow.Destinations.source()
        guard case .source(let line, let file) = route else { Issue.record("Wrong route"); return }
        #expect(line == expectedLine)
        #expect(file == #fileID)
    }

    @Test func closuresAndAutoclosuresRemainStoredClosures() {
        let routes: [ClosureDefaultReviewFlow.Destinations] = [
            .handler(), .handler(id: 8), .handler(callback: { 9 }), .handler(id: 8, callback: { 9 }),
        ]
        for (route, values) in zip(routes, [(42, 7), (8, 7), (42, 9), (8, 9)]) {
            guard case .handler(let id, let callback) = route else { Issue.record("Wrong route"); continue }
            #expect(id == values.0)
            #expect(callback() == values.1)
        }
        guard case .autoclosure(let value) = ClosureDefaultReviewFlow.Destinations.autoclosure() else {
            Issue.record("Wrong route"); return
        }
        #expect(value() == 42)
        let aliased: [ClosureDefaultReviewFlow.Destinations] = [.aliasHandler(), .aliasHandler(callback: { 9 })]
        for (route, expected) in zip(aliased, [7, 9]) {
            guard case .aliasHandler(let id, let callback) = route else { Issue.record("Wrong route"); continue }
            #expect(id == 42)
            #expect(callback() == expected)
        }
    }
}
