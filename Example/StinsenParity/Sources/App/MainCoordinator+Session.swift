import SwiftUI
import Scaffolding

// MARK: - Session
// Void return types are never macro-tracked — no attribute needed.

extension MainCoordinator {
    /// Called by the login and registration flows once they have a user.
    /// The presented flow hands its result up and this swaps the root;
    /// nothing observes anyone else's state.
    func signIn(_ user: User) {
        auth.signIn(user)
        setRoot(.authenticated(user: user))
        toasts.show("Signed in as \(user.username)", symbol: "person.crop.circle.badge.checkmark")
    }

    /// Reached from `ProfileScreen`, four levels down, via
    /// `ancestor(ofType:)` — the coordinator-side way up the tree.
    func signOut() {
        auth.signOut()
        setRoot(.unauthenticated)
        toasts.showNeutral("Signed out", symbol: "person.crop.circle.badge.xmark")
    }
}

// MARK: - Deep links

extension MainCoordinator {
    /// `parity://todo/<name>`.
    ///
    /// Deep linking lives on the coordinator, never in a view: one entry
    /// point resolves the URL and hands it to the shell, which walks its
    /// own tree — typed trailing closures through the tabs on iPhone, two
    /// column swaps on iPad and Mac. This function knows neither.
    func handle(_ url: URL) {
        guard let link = DeepLink(url: url) else {
            toasts.showWarning("Not a link this app knows: \(url.absoluteString)")
            return
        }

        guard let authenticated = liveShell() else {
            toasts.showWarning("Sign in first, then try the link again.")
            return
        }

        switch link {
        case .todo(let name):
            authenticated.openTodo(named: name)
        }
    }

    /// Finds the live authenticated shell without holding a reference to
    /// it, and without caring which shape it is. `hierarchySnapshot()`
    /// never materialises anything it hasn't already built, so this is
    /// side-effect free.
    private func liveShell() -> (any AuthenticatedShell)? {
        hierarchySnapshot().compactMap { $0.coordinator as? any AuthenticatedShell }.first
    }
}

// MARK: - Chrome

extension MainCoordinator {
    /// In an extension the macro never sees this — no @ScaffoldingIgnored
    /// needed, unlike a `some View` helper in the class body.
    ///
    /// Deliberately *not* setting `.tint`: the app follows whatever accent
    /// the user chose in System Settings, which is what every Apple app
    /// does and what a bespoke brand colour throws away.
    func customize(_ view: AnyView) -> some View {
        view
    }
}
