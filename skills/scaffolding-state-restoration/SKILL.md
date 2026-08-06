---
description: "Persist and restore navigation state, and debug the live coordinator tree, in apps using the Scaffolding SwiftUI library. Consult when implementing state restoration / scene restoration ('return the user where they left off'), when using @Scaffoldable(codable: true), captureNavigationState(), restoreNavigationState(from:), FlowStack(root:pushing:), or debugHierarchy(), or when debugging why navigation state looks wrong at runtime."
name: scaffolding-state-restoration
---
This guidance documents navigation-state persistence and debugging in the **Scaffolding** SwiftUI library.

## Opting in — `@Scaffoldable(codable: true)`

Capture requires each participating coordinator's generated `Destinations` enum to be `Codable`:

```swift
@MainActor @Observable @Scaffoldable(codable: true)
final class HomeCoordinator: @MainActor FlowCoordinatable {
    var stack = FlowStack<HomeCoordinator>(root: .home)

    func home() -> some View { HomeView() }
    func detail(id: Item.ID) -> some View { DetailView(id: id) }   // Codable payloads only
}
```

- Every route function's parameters must be `Codable` — the compiler enforces this at enum synthesis. Closure parameters (result callbacks) make a case non-codable; for restorable flows prefer the `awaiting:` result pattern (see `scaffolding-routing`) and keep payloads as value IDs, not model objects.
- Coordinators that don't opt in still work: their subtree is recorded without internal state and restores at its initial position (graceful degradation, not an error). Only calling `captureNavigationState()` **directly on** a non-codable coordinator throws (`NavigationStateError.unsupported`).

## Capture and restore

```swift
// On background / scene phase change:
let data = try appCoordinator.captureNavigationState()   // opaque Data — persist anywhere

// On cold launch, on a FRESHLY created coordinator of the same type:
let appCoordinator = AppCoordinator()
try appCoordinator.restoreNavigationState(from: data)
```

Typical wiring:

```swift
WindowGroup {
    coordinator.view
        .onChange(of: scenePhase) { _, phase in
            if phase == .background,
               let data = try? coordinator.captureNavigationState() {
                UserDefaults.standard.set(data, forKey: "nav-state")
            }
        }
        .task {
            if let data = UserDefaults.standard.data(forKey: "nav-state") {
                try? coordinator.restoreNavigationState(from: data)
            }
        }
}
```

Semantics:

- Capture walks the whole tree from the coordinator you call it on: flow roots + pushed/presented destinations, root-coordinator roots + modals, tab sets + selected index + per-tab children — recursively, for **already-created** descendants.
- Restoration **replays** the captured routes on top of the fresh coordinator's initial state (it goes through the normal `route`/`present`/`setRoot`/`setTabs` machinery).
- Routes that fail to decode — e.g. the `Destinations` enum changed shape between app versions — are **skipped silently**; a stale snapshot degrades instead of failing launch. Only structurally invalid data throws from `restoreNavigationState`.
- Treat the `Data` as opaque; never construct or edit `NavigationStateNode` yourself.

## Seeding a known start position — `FlowStack(root:pushing:)`

For deterministic starts (deep-link fallbacks, previews, tests) you don't need capture/restore — construct the flow already deep in its stack:

```swift
var stack = FlowStack<HomeCoordinator>(
    root: .home,
    pushing: [.detail(id: restoredId)]   // bottom first
)
```

The path materialises when the stack is first set up. Expose it via a hand-written coordinator initializer; the macro synthesises no `init(initialRoute:)`.

## Debugging the live tree — `debugHierarchy()`

Every coordinator can print a side-effect-free snapshot of its subtree (children not yet created are reported as `(not yet created)`, never materialised):

```swift
print(appCoordinator.debugHierarchy())

// From anywhere in the tree — hierarchyRoot walks to the topmost coordinator:
print(coordinator.hierarchyRoot.debugHierarchy())
```

```
AppRootCoordinator [root]
  root .main → MainTabCoordinator [tab]
    tab[0]* .home → HomeFlowCoordinator [flow]
      root .home
      push .settings
      sheet .sheetFlow → LeafFlowCoordinator [flow]
        root .leaf
    tab[1] .profile → ProfileFlowCoordinator [flow]
      root .profile
```

Each line shows the destination's role (`root`/`push`/`sheet`/`fullScreenCover`/`tab`), its `Destinations` case, and the child coordinator's type; `*` marks the selected tab. Reach for this first when routing behaves unexpectedly — it answers "who owns what" immediately.

It is also the most economical assertion in a unit test (`#expect(tree.contains("push .holding"))`) — see the `scaffolding-testing` skill for capture/restore and deep-link tests.
