import Testing
import Foundation
import Scaffolding
import ScaffoldingTesting
@testable import Checklist

/// Root swaps, root modals, and deep links — against the shipping
/// `AppCoordinator`, no test doubles. The layout is injected, so both
/// shells are covered on every platform.
@MainActor
@Suite("App root")
struct AppRootTests {

    @Test("starts in onboarding; finishing swaps to the tab shell")
    func onboardingSwap() {
        let app = AppCoordinator(layout: .tabs).activated()
        #expect(app.isRoot(.onboarding))

        app.finishOnboarding()

        #expect(app.isRoot(.main))
        #expect(app.descendant(ofType: MainTabCoordinator.self) != nil)
    }

    @Test("the split layout builds the three-column shell")
    func splitSwap() {
        let app = AppCoordinator(layout: .split).activated()
        app.finishOnboarding()

        #expect(app.descendant(ofType: MainSplitCoordinator.self) != nil)
        #expect(app.descendant(ofType: MainTabCoordinator.self) == nil)
    }

    @Test("a flow deep in the tree restarts onboarding via ancestor(ofType:)")
    func ancestorReachesRoot() {
        let app = AppCoordinator(layout: .tabs).activated()
        app.finishOnboarding()
        let settings = app.descendant(ofType: MainTabCoordinator.self)?
            .selectFirstTab(.settings, expecting: SettingsCoordinator.self)

        settings?.restartOnboarding()

        #expect(app.isRoot(.onboarding))
    }

    @Test("the tree inspector is a root modal, deduplicated by .distinct")
    func rootModal() {
        let app = AppCoordinator(layout: .tabs).activated()

        app.showHierarchy()
        app.showHierarchy()

        #expect(app.anyRoot.modals.count == 1)
        app.dismissModal()
        #expect(!app.isPresentingModal)
    }

    @Test("checklist://list lands in the Lists tab")
    func listDeepLink() {
        let app = AppCoordinator(layout: .tabs).activated()
        app.finishOnboarding()

        app.handle(URL(string: "checklist://list/home")!)

        #expect(app.hierarchyContains(MainTabCoordinator.self, .lists, as: .tab(index: 1, isSelected: true)))
        #expect(app.hierarchyContains(ListsCoordinator.self, .tasks, as: .push))
    }

    @Test("checklist://todo opens the task's detail in the split shell")
    func todoDeepLinkSplit() {
        let app = AppCoordinator(layout: .split).activated()
        app.finishOnboarding()

        app.handle(URL(string: "checklist://todo/6")!)

        #expect(app.hierarchyContains(MainSplitCoordinator.self, .detail, as: .column(.detail)))
        let split = app.descendant(ofType: MainSplitCoordinator.self)
        #expect(split?.selectedTodoID == 6)
    }

    @Test("deep links are ignored before onboarding finishes")
    func deepLinkGate() {
        let app = AppCoordinator(layout: .tabs).activated()

        app.handle(URL(string: "checklist://today")!)

        #expect(app.isRoot(.onboarding))
    }
}
