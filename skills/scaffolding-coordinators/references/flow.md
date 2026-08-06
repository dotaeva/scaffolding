# `FlowCoordinatable` — push/pop flows

The workhorse coordinator: wraps a `NavigationStack` internally. Its destinations live on the coordinator; the view tree never sees a path binding.

```swift
@MainActor @Observable @Scaffoldable
final class HomeCoordinator: @MainActor FlowCoordinatable {
    var stack = FlowStack<HomeCoordinator>(root: .home)

    func home()             -> some View         { HomeView() }
    func detail(item: Item) -> some View         { DetailView(item: item) }
    func settings()         -> any Coordinatable { SettingsCoordinator() }

    // Void helpers are never macro-tracked — no annotation needed.
    func openDetail(_ item: Item) { route(to: .detail(item: item)) }
    func openSettings() { present(.settings, as: .sheet) }
}
```

Render it with `coordinator.view` (e.g. in `WindowGroup`), or return it from another coordinator's route function.

**Never** put a `NavigationStack` (or `NavigationView` / `NavigationSplitView`) inside any view a flow route returns — the flow already provides one, and SwiftUI does not compose nested stacks. If a pushed screen needs its own hierarchy, return a child `FlowCoordinatable` instead.

## `FlowStack`

The observable state container. Constructed with a literal root case:

```swift
var stack = FlowStack<HomeCoordinator>(root: .home)
```

### Seeding an initial pushed path

`FlowStack(root:pushing:)` materialises pushed destinations (bottom first) when the stack is first set up — for cold-launch restoration to a known place, mid-flow previews, or constructing a coordinator already showing a detail:

```swift
@MainActor @Observable @Scaffoldable
final class HomeCoordinator: @MainActor FlowCoordinatable {
    var stack: FlowStack<HomeCoordinator>

    init(startingAt item: Item? = nil) {
        stack = item.map { FlowStack(root: .home, pushing: [.detail(item: $0)]) }
            ?? FlowStack(root: .home)
    }
    ...
}
```

There is **no** macro-synthesised `init(initialRoute:)` — if you want a parameterised start position, write the initializer yourself as above.

## Root swaps inside a flow

`setRoot(_:animation:)` exists on flows too (not just `RootCoordinatable`). Replacing a flow's root **clears all pushed destinations first** — they were pushed relative to the old root. Each removed destination's `onDismiss` fires exactly once (as a cancellation).

```swift
flow.setRoot(.home)                          // default animation
flow.setRoot(.home, animation: .snappy)      // one-off override
flow.setRootTransitionAnimation(.easeInOut)  // change the default (Flow and Root coordinators)
```

## `customize(_:)` — shared chrome for every screen

Every coordinator can wrap all content it presents:

```swift
// Returns `some View`, so the macro WOULD track it — @ScaffoldingIgnored is required here.
@ScaffoldingIgnored
func customize(_ view: AnyView) -> some View {
    view
        .navigationBarTitleDisplayMode(.inline)
        .tint(.indigo)
}
```

Do not construct navigation containers inside `customize` — modifiers only.

## State queries

Read-only introspection, all on the coordinator (views can read these since the coordinator is `@Observable`):

| Member | Meaning |
|---|---|
| `depth` | Number of *pushed* destinations above the root (modals not counted; `0` = at root) |
| `topDestination` | `Destinations.Meta?` of the topmost pushed destination, or the root's meta when nothing is pushed; modals ignored |
| `isInStack(_ meta)` | Whether the case appears anywhere in the stack (root not counted) |
| `count(of: meta)` | Occurrences of the case among pushed *and* presented destinations (root not counted) |
| `isPresentingModal` | Whether this flow currently presents a sheet/cover of its own |

For a printable snapshot of the whole live coordinator tree, call `debugHierarchy()` on any coordinator (see `scaffolding-state-restoration` skill).
