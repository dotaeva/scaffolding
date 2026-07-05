//
//  MacroIntegrationTests.swift
//  ScaffoldingTests
//
//  End-to-end checks that @Scaffoldable-generated coordinators work with
//  the new QOL APIs, including the codable: flag.
//

import Testing
import SwiftUI
import Observation
@testable import Scaffolding

@MainActor @Observable @Scaffoldable(codable: true)
final class MacroCodableCoordinator: @MainActor FlowCoordinatable {
    var stack = FlowStack<MacroCodableCoordinator>(root: .home)

    func home() -> some View { EmptyView() }
    func detail(id: Int) -> some View { EmptyView() }

    // Void return type — never tracked by the macro.
    func openDetail(_ id: Int) {
        route(to: .detail(id: id))
    }
}

@MainActor @Observable @Scaffoldable
final class MacroPlainCoordinator: @MainActor FlowCoordinatable {
    var stack = FlowStack<MacroPlainCoordinator>(root: .home)

    func home() -> some View { EmptyView() }
    func detail(id: Int) -> some View { EmptyView() }
}

@MainActor
@Suite("@Scaffoldable macro integration")
struct MacroIntegrationTests {

    @Test("codable: true generates a Codable Destinations enum that round-trips state")
    func codableMacroRoundTrip() throws {
        let flow = MacroCodableCoordinator()
        _ = flow.anyStack
        flow.route(to: .detail(id: 3))
        flow.route(to: .detail(id: 8))

        let data = try flow.captureNavigationState()

        let restored = MacroCodableCoordinator()
        try restored.restoreNavigationState(from: data)

        #expect(restored.depth == 2)
        #expect(restored.topDestination == .detail)
    }

    @Test("without codable: capture throws unsupported")
    func plainMacroThrows() {
        let flow = MacroPlainCoordinator()
        _ = flow.anyStack

        #expect(throws: NavigationStateError.self) {
            _ = try flow.captureNavigationState()
        }
    }

    @Test("macro-generated destinations work with the new QOL APIs")
    func macroWithQOLAPIs() {
        let flow = MacroCodableCoordinator()
        _ = flow.anyStack

        flow.route(to: .detail(id: 1), policy: .distinct)
        flow.route(to: .detail(id: 2), policy: .distinct) // same case on top — skipped
        #expect(flow.depth == 1)

        flow.replaceLast(with: .detail(id: 9))
        #expect(flow.depth == 1)

        flow.openDetail(4)
        #expect(flow.depth == 2)

        flow.pop(2)
        #expect(flow.depth == 0)
    }
}
