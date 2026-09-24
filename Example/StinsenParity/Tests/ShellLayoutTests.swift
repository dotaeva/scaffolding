import Testing
import Foundation
import Scaffolding
import ScaffoldingTesting
@testable import StinsenParity

/// Which shell the app root builds, and the entry points that must not
/// care which it was.
@MainActor
@Suite("Shell layout")
struct ShellLayoutTests {
    private func makeApp(layout: ShellLayout) -> MainCoordinator {
        // A scratch UserDefaults keeps the tests from seeing each other's
        // sessions, or the simulator's.
        let defaults = UserDefaults(suiteName: "test.\(UUID().uuidString)")!
        return MainCoordinator(
            auth: AuthenticationService(defaults: defaults),
            layout: layout
        ).activated()
    }

    @Test("the app root builds the shell its layout names")
    func rootPicksTheShell() {
        let split = makeApp(layout: .split)
        split.signIn(.preview)
        #expect(split.descendant(ofType: AuthenticatedSplitCoordinator.self) != nil)
        #expect(split.descendant(ofType: AuthenticatedCoordinator.self) == nil)

        let tabs = makeApp(layout: .tabs)
        tabs.signIn(.preview)
        #expect(tabs.descendant(ofType: AuthenticatedCoordinator.self) != nil)
    }

    @Test("a parity:// link resolves against whichever shell is live")
    func deepLinkReachesEitherShell() {
        let app = makeApp(layout: .split)
        app.signIn(.preview)
        let split = app.descendant(ofType: AuthenticatedSplitCoordinator.self)
        let name = split!.store.all[0].name

        let path = name.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!
        app.handle(URL(string: "parity://todo/\(path)")!)

        #expect(split?.section == .todos)
        #expect(split?.selectedTodoID == split?.store.all[0].id)
    }
}
