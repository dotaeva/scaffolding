# Previews in a Scaffolding project

A preview of `coordinator.view` renders the hierarchy and its environment. A preview of a **bare leaf view** bypasses that hierarchy. Configure each according to what it renders.

## 1. Inject the coordinator any view reads

A non-optional `@Environment(SomeCoordinator.self)` lookup fails when that type has not been injected; this is not a Swift concurrency issue. Always pass the coordinator explicitly:

```swift
#Preview("DetailView · pushed") {
    DetailView(item: .earth)
        .environment(HomeCoordinator())
}
```

If the view also reads ancestor coordinators, inject each type it uses. Views that only use native values like `@Environment(\.dismiss)` need nothing extra.

## 2. Preview coordinators at their real root — no `initialRoute:`

The macro does **not** synthesise an `init(initialRoute:)`; `FlowStack` is constructed with a literal root case:

```swift
// ❌ Doesn't compile — no such initialiser exists.
#Preview { HomeCoordinator(initialRoute: .detail(item: planet)).view }

// ✅ Coordinator at its root.
#Preview("Home flow") { HomeCoordinator().view }
```

To preview a *mid-flow* state, either render the leaf view directly (rule 1), or give the coordinator a hand-written initializer that seeds the stack:

```swift
init(startingAt item: Item) {
    stack = FlowStack(root: .home, pushing: [.detail(item: item)])
}

#Preview("Home · at detail") { HomeCoordinator(startingAt: .earth).view }
```

`FlowStack(root:pushing:)` is a real API (path materialises bottom-first at setup) — it's the supported way to construct a flow already deep in its stack, for previews and cold-launch alike.

## 3. Bare views receive default destination metadata

`\.destination` is set when the framework materialises a destination through `route`/`present`/`setRoot`. A view rendered alone in `#Preview` was never materialised, so `destination.routeType`, `presentationType`, and `meta` read as the **default (`.root`)** — not what the screen shows when actually pushed or presented.

- A bare-view preview is for layout. Preview the coordinator to verify destination-dependent chrome.
- To *visually* check a pushed/presented state, preview the owning coordinator (seeded per rule 2, or via a deep-link method your app already exposes) rather than the bare view.
- A view whose layout branches on `destination.routeType` will always show its `.root` branch in a bare preview — expected, not a bug.
