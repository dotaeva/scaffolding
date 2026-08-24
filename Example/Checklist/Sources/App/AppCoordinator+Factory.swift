import SwiftUI
import Scaffolding

// MARK: - Factory
// Where each route's screen is actually assembled: views get their
// ViewModels here, child coordinators get their dependencies. The
// route table stays in the class body because @Scaffoldable scans
// only the class declaration — a route in an extension is silently
// untracked — while these `make…` helpers are invisible to it, so
// they need no @ScaffoldingIgnored.

extension AppCoordinator {
    func makeOnboarding() -> any Coordinatable {
        // Result delivery: the presenter installs the completion at
        // construction time; the child never reaches back up the tree.
        OnboardingCoordinator(store: store) { [weak self] in
            self?.finishOnboarding()
        }
    }

    func makeMain() -> any Coordinatable {
        layout == .split
            ? MainSplitCoordinator(store: store)
            : MainTabCoordinator(store: store)
    }

    /// View-only route, presented above whatever the current root is.
    func makeHierarchy() -> some View { HierarchySheet() }
}
