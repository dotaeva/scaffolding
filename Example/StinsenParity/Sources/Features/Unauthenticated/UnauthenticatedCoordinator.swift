import SwiftUI
import Scaffolding

/// Login, forgot-password, and registration.
///
/// In the Stinsen demo this flow needs a `NavigationViewCoordinator`
/// wrapper to get a `NavigationView` around it. A `FlowCoordinatable`
/// *is* the `NavigationStack`, so there is no wrapper type here — and no
/// `NavigationStack` anywhere in the views either.
@MainActor
@Observable
@Scaffoldable
final class UnauthenticatedCoordinator: @MainActor FlowCoordinatable {
    var stack = FlowStack<UnauthenticatedCoordinator>(root: .login)

    let services = UnauthenticatedServices()
    let toasts: ToastCenter

    /// Set while a service call is in flight, so the screens can disable
    /// their buttons. Navigation state stays on the coordinator; this is
    /// domain state, and it is *still* not in the view.
    var isWorking = false

    init(toasts: ToastCenter) {
        self.toasts = toasts
    }

    // MARK: Routes
    // The route table: one line per destination, with the bodies in
    // UnauthenticatedCoordinator+Factory.swift. These declarations have to
    // stay in the class body — @Scaffoldable scans only the class
    // declaration, so a route moved to an extension is silently untracked.

    func login() -> some View { makeLogin() }

    func forgotPassword() -> some View { makeForgotPassword() }

    /// A child *coordinator*, so registration owns its own two-step stack
    /// and hands a `User` back when it finishes.
    func registration() -> any Coordinatable { makeRegistration() }
}
