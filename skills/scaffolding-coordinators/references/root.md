# `RootCoordinatable` — atomic root swaps

Use when the **entire view hierarchy** is replaced at once: authentication ↔ main app, onboarding ↔ home, workspace switching. Typically the app's outermost coordinator.

```swift
@MainActor @Observable @Scaffoldable
final class AppCoordinator: @MainActor RootCoordinatable {
    var root = Root<AppCoordinator>(root: .unauthenticated)

    func unauthenticated() -> any Coordinatable { LoginCoordinator() }
    func authenticated()   -> any Coordinatable { MainTabCoordinator() }

    func signIn()  { setRoot(.authenticated) }
    func signOut() { setRoot(.unauthenticated) }
}
```

Hook it into the app:

```swift
@main
struct MyApp: App {
    @State private var coordinator = AppCoordinator()

    var body: some Scene {
        WindowGroup {
            coordinator.view
        }
    }
}
```

## API surface

```swift
appCoordinator.setRoot(.authenticated)                       // swap the whole tree
appCoordinator.setRoot(.authenticated, animation: .easeOut)  // one-off animation override
appCoordinator.setRootTransitionAnimation(.snappy)           // change the default
appCoordinator.isRoot(.authenticated)                        // Bool — compare by Meta
```

`setRoot` tears down the previous subtree; the old root destination's `onDismiss` (and any destinations inside it) resolve exactly once. Swapping roots is intentionally destructive — a fresh child coordinator is created each time the route function runs.

Typed variants for deep linking (`setRoot(_:animation:) { (tab: MainTabCoordinator) in ... }`, `setRoot(_:expecting:)`) are covered in `scaffolding-routing` → `deep-linking.md`.

## Modals above the root

A `RootCoordinatable` can present sheets/covers that float above whatever the current root is — ideal for cross-cutting UI that must survive a root swap decision (e.g. a forced-update sheet):

```swift
appCoordinator.present(.whatsNew)                 // sheet by default
appCoordinator.present(.forcedUpdate, as: .fullScreenCover)
appCoordinator.dismissModal()                     // presenter-side close
appCoordinator.isPresentingModal                  // Bool
```

Async variants (`presentAndWait`, `present(_:awaiting:)`) work here too — see `scaffolding-routing` → `async-navigation.md`.

## Notes

- A view-only route (`some View`) is a valid root, but roots are usually child coordinators — the root of an app section almost always needs its own navigation.
- Don't use `RootCoordinatable` for ordinary forward navigation; that's a push (`FlowCoordinatable`) or a modal. Root swaps are for state changes where "back" must not exist.
- A typical app: `AppCoordinator (Root)` → `LoginCoordinator (Flow)` | `MainTabCoordinator (Tab)` → per-tab `Flow` coordinators.
