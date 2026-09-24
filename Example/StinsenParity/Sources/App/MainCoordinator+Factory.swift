import SwiftUI
import Scaffolding

// MARK: - Factory
// Where each route's screen is actually assembled: views get their
// dependencies here, child coordinators get theirs. The route table stays
// in the class body because @Scaffoldable scans only the class
// declaration — a route in an extension is silently untracked — while
// these `make…` helpers are invisible to it, so they need no
// @ScaffoldingIgnored.

extension MainCoordinator {
    func makeUnauthenticated() -> any Coordinatable {
        UnauthenticatedCoordinator(toasts: toasts)
    }

    /// One route, two shells. Everything below the shell — the four
    /// flows, the create sub-flow, the deep links — is the same either
    /// way; only the container differs.
    func makeAuthenticated(user: User) -> any Coordinatable {
        layout == .split
            ? AuthenticatedSplitCoordinator(user: user, toasts: toasts)
            : AuthenticatedCoordinator(user: user, toasts: toasts)
    }
}
