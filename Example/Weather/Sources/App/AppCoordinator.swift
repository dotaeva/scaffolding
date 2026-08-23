import SwiftUI
import Scaffolding

/// Root of the tree. A `RootCoordinatable` swaps the entire hierarchy
/// atomically — onboarding ↔ main — with no "back" between the states.
///
/// `codable: true` enables whole-tree navigation-state capture (see
/// AppCoordinator+Restoration); every route here is payload-free, so the
/// generated `Destinations` enum synthesizes `Codable` for free.
@MainActor
@Observable
@Scaffoldable(codable: true)
final class AppCoordinator: @MainActor RootCoordinatable {
    var root = Root<AppCoordinator>(root: .onboarding)

    /// Domain state, injected into children by init and into views via
    /// `.environment` at the entry point. Stored properties are never
    /// macro-tracked.
    let store = WeatherStore()

    /// Tabs on iPhone, split view on iPad/macOS. Injected so tests can
    /// build either shape on any platform.
    let layout: MainLayout

    init(layout: MainLayout = .current) {
        self.layout = layout
        // Default animation for every root swap; setRoot(_:animation:)
        // overrides it per call.
        setRootTransitionAnimation(.smooth(duration: 0.35))
    }

    // MARK: Routes
    // Routes must be declared in the class body — @Scaffoldable scans only
    // the class declaration, never extensions.

    func onboarding() -> any Coordinatable {
        // Result delivery: the presenter installs the completion at
        // construction time; the child never reaches back up the tree.
        OnboardingCoordinator(store: store) { [weak self] in
            self?.finishOnboarding()
        }
    }

    func main() -> any Coordinatable {
        layout == .split
            ? WeatherSplitCoordinator(store: store)
            : MainTabCoordinator(store: store)
    }

    // View-only route, presented modally above whatever the root shows.
    func hierarchyDump() -> some View { HierarchyDumpSheet() }
}

// MARK: - Root swaps

extension AppCoordinator {
    func finishOnboarding() {
        store.isOnboarded = true
        setRoot(.main)
    }

    /// Settings → "Reset onboarding". Reached via ancestor(ofType:) from a
    /// coordinator deep in the tree.
    func resetOnboarding() {
        store.isOnboarded = false
        // One-off animation override.
        setRoot(.onboarding, animation: .easeInOut(duration: 0.25))
    }
}

// MARK: - Modals above the root

extension AppCoordinator {
    /// Debug sheet with the live coordinator tree — device shake on iOS
    /// (⌃⌘Z in the simulator), ⇧⌘D on macOS. Presented on the root so it
    /// works from any tab, column, flow, or the onboarding screens.
    func showHierarchyDump() {
        present(.hierarchyDump, as: .sheet(detents: [.medium, .large]), policy: .distinct)
    }
}

// MARK: - Chrome

extension AppCoordinator {
    // In an extension the macro never sees this — no @ScaffoldingIgnored
    // needed, unlike a `some View` helper declared in the class body.
    func customize(_ view: AnyView) -> some View {
        view.fontDesign(.rounded)
    }
}
