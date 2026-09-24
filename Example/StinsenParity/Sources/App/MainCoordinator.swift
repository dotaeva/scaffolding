import SwiftUI
import Scaffolding

/// Root of the tree, and the app's composition root.
///
/// The Stinsen demo declares two `@Root`s on a `NavigationCoordinatable`
/// and flips between them by observing an `ObservableObject` from
/// `customize(_:)`. Scaffolding has a coordinator type for exactly this
/// shape: a `RootCoordinatable` swaps the whole hierarchy atomically, and
/// the swap is an ordinary method call rather than a view-side
/// subscription — so no view is involved in the auth transition at all.
@MainActor
@Observable
@Scaffoldable
final class MainCoordinator: @MainActor RootCoordinatable {
    var root: Root<MainCoordinator>

    /// Owned here so it outlives every root swap — see ``ToastCenter``.
    let toasts = ToastCenter()

    let auth: AuthenticationService

    /// Tabs on iPhone, columns on iPad and Mac. A value rather than a
    /// `#if`, so a test can build either shape on any device.
    let layout: ShellLayout

    init(
        auth: AuthenticationService = AuthenticationService(),
        layout: ShellLayout = .current
    ) {
        self.auth = auth
        self.layout = layout
        // Launching straight into the authenticated tree when a session
        // was restored, exactly like the Stinsen demo's init.
        self.root = Root<MainCoordinator>(
            root: auth.currentUser.map { .authenticated(user: $0) } ?? .unauthenticated
        )
        setRootTransitionAnimation(.smooth(duration: 0.3))
    }

    // MARK: Routes
    // The route table: one line per destination, with the bodies in
    // MainCoordinator+Factory.swift. These declarations have to stay in
    // the class body — @Scaffoldable scans only the class declaration, so
    // a route moved to an extension is silently untracked.

    func unauthenticated() -> any Coordinatable { makeUnauthenticated() }

    func authenticated(user: User) -> any Coordinatable { makeAuthenticated(user: user) }
}
