# Deep linking — typed child resolution

Every navigation method that resolves a child coordinator ships two typed variants:

1. **Trailing closure** — fires once with the resolved child cast to `T`:
   `route(to:) { (child: T) in }`, `present(_:as:) { ... }`, `setRoot(_:) { ... }`, `popToFirst/Last(_:) { ... }`, `selectFirstTab/selectLastTab(_:) { ... }`, `select(index:/id:) { ... }`, `appendTab/insertTab(_:) { ... }`.
2. **`expecting:`** — returns `T?` directly, flattening chains:
   `route(to:expecting:)`, `present(_:as:expecting:)`, `setRoot(_:expecting:)`, `popToFirst/Last(_:expecting:)`, `selectFirstTab(_:expecting:)`, `select(index:expecting:)`, etc.

If the destination is view-only, resolves to a different type, or the policy skipped the navigation, the closure doesn't fire / the return is `nil`.

## Walking the tree from a cold launch

```swift
@MainActor @Observable @Scaffoldable
final class AppCoordinator: @MainActor RootCoordinatable {
    var root = Root<AppCoordinator>(root: .unauthenticated)

    func unauthenticated() -> any Coordinatable { LoginCoordinator() }
    func authenticated()   -> any Coordinatable { MainTabCoordinator() }

    /// Land on a user's profile from a URL / push / quick action.
    func openProfile(userId: Int) {
        setRoot(.authenticated) { (tab: MainTabCoordinator) in
            tab.selectFirstTab(.profile) { (profile: ProfileCoordinator) in
                profile.route(to: .userDetail(id: userId))
            }
        }
    }
}
```

The same chain with `expecting:` (flatter, easier to branch):

```swift
func openProfile(userId: Int) {
    let tab = setRoot(.authenticated, expecting: MainTabCoordinator.self)
    let profile = tab?.selectFirstTab(.profile, expecting: ProfileCoordinator.self)
    profile?.route(to: .userDetail(id: userId))
}
```

Entry point wiring:

```swift
WindowGroup {
    coordinator.view
        .onOpenURL { url in
            if let userId = parseUserURL(url) {
                coordinator.openProfile(userId: userId)
            }
        }
}
```

## Rules

- **Match the concrete type to the route's factory.** For `func authenticated() -> any Coordinatable { MainTabCoordinator() }` the closure parameter / `expecting:` type must be `MainTabCoordinator`, or nothing fires. The closures are typed `@MainActor (T) -> Void`.
- **Don't stash child-coordinator references** outside the chain to deep-link later. The typed overloads hand you the right reference at the right time; stored references go stale after root swaps.
- **Deep-linking lives on a coordinator** (or the orchestrator owning the URL/push entry point). A view dispatching multiple `route`/`setRoot` calls in sequence is a smell — wrap the sequence in one coordinator method and have the view call it.
- Tab-selection variants resolve tabs eagerly, so chains work on cold launch before the `TabView` has rendered.
- For restoring *arbitrary* positions (rather than known deep-link targets), prefer navigation-state capture/restore — see the `scaffolding-state-restoration` skill.
