import Testing
import Scaffolding
import ScaffoldingTesting
@testable import Checklist

/// Onboarding is a paged `TabCoordinatable`: the buttons select pages,
/// swiping does the same thing through the selection binding, and the
/// result reaches the presenter through its installed closure.
@MainActor
@Suite("Onboarding pages")
struct OnboardingFlowTests {
    private func makePages(
        onComplete: @escaping @MainActor () -> Void = { }
    ) -> OnboardingCoordinator {
        OnboardingCoordinator(store: TodoStore(), onComplete: onComplete).activated()
    }

    @Test("three pages, starting on welcome, with the native bar hidden")
    func initialPage() {
        let pages = makePages()

        #expect(pages.tabItems.tabs.count == 3)
        #expect(pages.tabItems.tabBarVisibility == .hidden)
        #expect(pages.hierarchyContains(
            OnboardingCoordinator.self, .welcome, as: .tab(index: 0, isSelected: true)
        ))
    }

    @Test("the buttons move forward one page at a time")
    func forward() {
        let pages = makePages()

        pages.showPreferences()
        #expect(pages.hierarchyContains(
            OnboardingCoordinator.self, .preferences, as: .tab(index: 1, isSelected: true)
        ))

        pages.showReady()
        #expect(pages.hierarchyContains(
            OnboardingCoordinator.self, .ready, as: .tab(index: 2, isSelected: true)
        ))
    }

    @Test("start over returns to the first page")
    func startOver() {
        let pages = makePages()
        pages.showReady()

        pages.startOver()

        #expect(pages.hierarchyContains(
            OnboardingCoordinator.self, .welcome, as: .tab(index: 0, isSelected: true)
        ))
    }

    @Test("selecting the same page again changes nothing")
    func idempotentSelection() {
        let pages = makePages()
        pages.showPreferences()
        let selected = pages.tabItems.selectedTab

        pages.showPreferences()

        #expect(pages.tabItems.selectedTab == selected)
    }

    @Test("finishing calls the completion exactly once")
    func completion() {
        var completions = 0
        let pages = makePages { completions += 1 }

        pages.finish()

        #expect(completions == 1)
    }

    @Test("preferences write straight through to the store")
    func preferencesWriteThrough() {
        let store = TodoStore()
        let viewModel = OnboardingViewModel(store: store)

        viewModel.sortByDueDate = false
        viewModel.showsCompleted = true

        #expect(!store.sortByDueDate)
        #expect(store.showsCompleted)
    }
}
