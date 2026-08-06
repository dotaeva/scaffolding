# Typed coordinator injection

Scaffolding installs each coordinator into the environment of every view it manages using SwiftUI's `@Observable` environment (`.environment(object)` / `@Environment(Type.self)`).

## What's injected

For a view materialised by `HomeCoordinator` (itself a child of `MainTabCoordinator`, under `AppCoordinator`), **all three** are available:

```swift
struct HomeView: View {
    @Environment(HomeCoordinator.self)    private var coordinator   // nearest — the usual choice
    @Environment(MainTabCoordinator.self) private var tabs          // ancestor: switch tabs, badges
    @Environment(AppCoordinator.self)     private var app           // ancestor: sign-out root swap

    var body: some View {
        Button("Sign out") { app.signOut() }
    }
}
```

Prefer the **nearest** coordinator for the view's own navigation. Reach for an ancestor only for actions that genuinely belong to it (root swaps, tab switching) — or better, expose a method on the nearest coordinator that walks up, keeping views single-coordinator. `ancestor(ofType:)` makes that a one-liner:

```swift
// On HomeCoordinator — the view just calls coordinator.signOut().
func signOut() {
    ancestor(ofType: AppCoordinator.self)?.setRoot(.unauthenticated)
}
```

`@Environment(SomeCoordinator.self)` **crashes** when the type isn't in the environment (missing ancestor type, view rendered outside the hierarchy, previews without injection). If a view might render both inside and outside a flow, take the optional form:

```swift
@Environment(HomeCoordinator.self) private var coordinator: HomeCoordinator?
```

## Opting out — `@Scaffoldable(injectsCoordinator: false)`

```swift
@MainActor @Observable @Scaffoldable(injectsCoordinator: false)
final class InternalFlowCoordinator: @MainActor FlowCoordinatable { ... }
```

Semantics:

- Only **this coordinator** is hidden from descendant views' typed environment. Its ancestors are still walked and injected normally.
- Use it when a flow hosts reusable screens that must not bind to the concrete coordinator type. Those screens navigate through callbacks handed in at construction, or use SwiftUI's `@Environment(\.dismiss)` for plain back/close.

## Rules

- Coordinators are not views: they never read `@Environment`. Data a coordinator needs arrives through its initializer.
- Views never receive coordinators via `init` when they live inside the hierarchy — the environment is the delivery mechanism. Constructor injection is for previews and for views rendered outside coordinator management.
- Don't `.environment(...)` a coordinator manually in app code; the framework handles it. Manual injection is a preview-only technique (see `previews.md`).
