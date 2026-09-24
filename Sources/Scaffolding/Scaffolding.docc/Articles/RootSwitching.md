# Switching App Roots

Swap the whole app branch for sign-in, onboarding, and other app-wide state
changes.

## Overview

A ``RootCoordinatable`` shows one root destination at a time.
``RootCoordinatable/setRoot(_:animation:)`` removes the current branch with
all its pushes and modals, then builds the new one — even when the case is
unchanged.

```swift
@MainActor @Observable @Scaffoldable
final class AppCoordinator: @MainActor RootCoordinatable {
    var root = Root<AppCoordinator>(root: .unauthenticated)

    func unauthenticated() -> any Coordinatable { LoginCoordinator() }
    func authenticated() -> any Coordinatable { MainTabCoordinator() }
    func login() -> any Coordinatable { LoginCoordinator() }
}

extension AppCoordinator {
    func signIn() { setRoot(.authenticated) }

    func signOut() {
        dismissAllModals()
        setRoot(.unauthenticated)
    }
}
```

Mount it once with `coordinator.view`; see <doc:Essentials#Mount-the-tree-once>.

## Give the swap one owner

Expose actions like `signOut()` on the root and call them from anywhere,
instead of calling `setRoot` from leaf code:

```swift
// In a view, at any depth
@Environment(AppCoordinator.self) private var app
Button("Sign out") { app.signOut() }

// In a coordinator
ancestor(ofType: AppCoordinator.self)?.signOut()
```

This works when the caller can name `AppCoordinator`. A feature in its own
package can't; inject `signOut()` as a capability instead — see
<doc:ModularApps#Inject-capabilities-for-app-level-actions>.

## Swap after a result

Present login, await its token, then swap:

```swift
func startLogin() async {
    guard let token = await present(.login, awaiting: AuthToken.self) else { return }
    session = token
    setRoot(.authenticated)
}
```

The login flow finishes with `dismissCoordinator(returning: token)`.

## API

| Intent | Method |
|---|---|
| Replace the branch | ``RootCoordinatable/setRoot(_:animation:)`` |
| Replace it and use the child | ``RootCoordinatable/setRoot(_:animation:expecting:)`` |
| Check the branch | ``RootCoordinatable/isRoot(_:)`` |
| Present above the branch | ``Coordinatable/present(_:as:policy:)``; see <doc:ModalsAndResults> |
| Default animation | ``RootCoordinatable/setTransitionAnimation(_:)`` |

## Rules

- Modals owned **directly by the root coordinator** survive `setRoot`. Call
  `dismissAllModals()` when the new state must clear them.
- Check `isRoot(_:)` before swapping when a repeated call should keep the
  current branch.
- A top-level root coordinator has no parent; `dismissCoordinator()` does
  nothing. Hosted as a pushed or modal child, it dismisses its branch.
- A ``SplitCoordinatable`` can be a root destination.

## See Also

- <doc:Essentials>
- <doc:DeepLinking>
