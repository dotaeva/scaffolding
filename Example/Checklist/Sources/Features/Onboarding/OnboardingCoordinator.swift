import SwiftUI
import Scaffolding

/// First-launch flow as a **paged** experience: welcome → preferences →
/// ready, swipeable with page dots.
///
/// Pages are tabs, not pushes, so this is a `TabCoordinatable` with the
/// native bar hidden and `.page` style applied in `customize(_:)`. Which
/// page is showing stays coordinator state — no `@State` page index in a
/// view — and the buttons simply select a tab. Each route also returns a
/// label, which macOS (where paging doesn't exist) renders as a normal
/// labelled tab strip.
///
/// The result is delivered through the closure the presenter installed at
/// construction time; `AppCoordinator` then swaps the root.
@MainActor
@Observable
@Scaffoldable
final class OnboardingCoordinator: @MainActor TabCoordinatable {
    var tabItems = TabItems<OnboardingCoordinator>(
        tabs: [.welcome, .preferences, .ready],
        visibility: .hidden          // the page dots are the only chrome
    )

    private let store: TodoStore
    private let onComplete: @MainActor () -> Void

    init(store: TodoStore, onComplete: @escaping @MainActor () -> Void) {
        self.store = store
        self.onComplete = onComplete
    }

    // MARK: Routes
    // (some View, some View) ⇒ a view-only tab plus its label.

    func welcome() -> (some View, some View) {
        (WelcomeView(), pageLabel("Welcome", symbol: "hand.wave"))
    }

    func preferences() -> (some View, some View) {
        (PreferencesStepView(viewModel: OnboardingViewModel(store: store)),
         pageLabel("Preferences", symbol: "slider.horizontal.3"))
    }

    func ready() -> (some View, some View) {
        (ReadyView(), pageLabel("Ready", symbol: "checkmark.seal"))
    }

    // Genuinely needs @ScaffoldingIgnored: declared in the class body and
    // returning `some View`, so the macro would otherwise emit a bogus
    // `.customize` destination. (Other coordinators declare it in an
    // extension, where the macro never looks — both placements appear in
    // this app on purpose.)
    @ScaffoldingIgnored
    func customize(_ view: AnyView) -> some View {
        #if os(iOS)
        view
            .tabViewStyle(.page(indexDisplayMode: .never))
            .safeAreaInset(edge: .bottom) { PageIndicator() }
        #else
        view
        #endif
    }
}

// MARK: - Page labels

extension OnboardingCoordinator {
    /// In an extension, so the macro never sees this `some View` helper —
    /// no `@ScaffoldingIgnored` required, unlike `customize` above.
    ///
    /// iOS pages must carry **no** label: the paged index view reuses tab
    /// images as its indicators, which replaces the page dots with icons.
    /// macOS has no page style, so there the label names the tab.
    func pageLabel(_ title: String, symbol: String) -> some View {
        #if os(iOS)
        EmptyView()
        #else
        Label(title, systemImage: symbol)
        #endif
    }
}

// MARK: - Pages
// Void return types are never macro-tracked — no attribute needed.

extension OnboardingCoordinator {
    func showPreferences() { selectFirstTab(.preferences) }
    func showReady() { selectFirstTab(.ready) }

    /// Back to the first page, from wherever the user got to.
    func startOver() { selectFirstTab(.welcome) }

    func finish() { onComplete() }
}
