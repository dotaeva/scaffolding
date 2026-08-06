---
description: "Authoritative reference for the @Environment values the Scaffolding SwiftUI library injects into every view it manages. Consult when a view reads @Environment(SomeCoordinator.self) or @Environment(\\.destination), when writing adaptive chrome that changes with push/sheet/cover presentation, when using @Scaffoldable(injectsCoordinator: false), or when writing #Preview for views inside a Scaffolding hierarchy. Covers: - Typed coordinator injection: the nearest coordinator AND all its ancestors are in the environment; opt-out semantics. - \\.destination: Destination metadata (routeType vs presentationType, meta, modalConfiguration, badge) and the adaptive top-bar pattern. - Previews: injecting coordinators manually, why \\.destination is unreliable in #Preview, seeding mid-flow states."
name: scaffolding-environment
---
This guidance documents the environment surface of the **Scaffolding** SwiftUI navigation library. At runtime, every view materialised through a coordinator (`route`, `present`, `setRoot`, tabs) receives two kinds of environment values automatically:

1. **Typed coordinators** — `@Environment(HomeCoordinator.self)`: the owning coordinator *and every ancestor* up the parent chain (each injectable unless opted out).
2. **`\.destination`** — metadata about how the current screen was reached (root / push / sheet / full-screen cover, which `Destinations` case, presenter-side sheet configuration).

Views navigate by reading the typed coordinator and calling methods — never by owning path/sheet state. Native environment values (`\.dismiss`, `\.scenePhase`, `\.openURL`) compose normally; `\.dismiss` works for both pops and modal dismissal because Scaffolding wraps `NavigationStack`, and is the right tool for reusable components that only need to close/go back without knowing the coordinator type.

```swift
struct DetailView: View {
    @Environment(HomeCoordinator.self) private var coordinator   // typed: full route surface
    @Environment(\.destination) private var destination          // how did I get here?

    var body: some View {
        Button("Edit") { coordinator.route(to: .editor) }
    }
}
```

# References
- `references/coordinator-injection.md`: Use when a view reads `@Environment(SomeCoordinator.self)`, when choosing which coordinator a view should talk to, or when using `@Scaffoldable(injectsCoordinator: false)`. Covers ancestor-chain injection, opt-out semantics, and crash-avoidance rules.
- `references/destination.md`: Use when a view adapts to how it was presented — back-chevron vs Close button, layout differences per route — or reads sheet configuration. Covers every public property of `Destination`, the `routeType` vs `presentationType` distinction, `meta` matching, and the canonical adaptive top-bar pattern.
- `references/previews.md`: Use when writing `#Preview` for any view or coordinator in a Scaffolding project. Covers injecting coordinators manually, why `\.destination` reads as `.root` in previews, and how to seed mid-flow preview states.

The same caveat applies in tests, where no view is rendered at all: use the `scaffolding-testing` skill for unit-testing coordinators.
