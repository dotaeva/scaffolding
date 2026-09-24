# Deep linking — typed child resolution

Use `expecting:` to navigate and return a resolved child as `T?`: `route`,
`present`, `setRoot`, `popToFirst` / `popToLast`, tab selection/insertion,
and split-column setters all support it. A view-only destination, mismatched
child type, or skipped policy returns nil. The navigation is not undone by a
child-type mismatch. Typed trailing closures are deprecated; do not generate them.

For a push or presentation that also returns a dismissal result, combine
`expecting:` with `awaiting:`. This returns `(coordinator, result)` immediately:

```swift
let (settings, result) = present(
    .settings, expecting: SettingsCoordinator.self, awaiting: Void.self
)
settings?.route(to: .account)
_ = await result()
```

Only the result closure suspends. See `async-navigation.md` for cancellation,
policy skips, and type mismatches. This replaces deprecated calls that needed
both a typed child callback and `onDismiss:`.

## Walking the tree from a cold launch

```swift
@MainActor @Observable @Scaffoldable
final class AppCoordinator: @MainActor RootCoordinatable {
    var root = Root<AppCoordinator>(root: .unauthenticated)

    func unauthenticated() -> any Coordinatable { LoginCoordinator() }
    func authenticated()   -> any Coordinatable { MainTabCoordinator() }

    /// Land on a user's profile from a URL / push / quick action.
    func openProfile(userId: Int) {
        let tabs = setRoot(.authenticated, expecting: MainTabCoordinator.self)
        let profile = tabs?.selectFirstTab(.profile, expecting: ProfileCoordinator.self)
        profile?.route(to: .userDetail(id: userId))
    }
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
