---
description: "Use Scaffolding coordinator environment injection and destination metadata in SwiftUI views and previews. Covers ancestor access, opt-out, routeType versus presentationType, and isolated-view preview setup."
name: scaffolding-environment
---
This guidance documents the environment surface of the **Scaffolding** SwiftUI navigation library. At runtime, every view materialised through a coordinator (`route`, `present`, `setRoot`, tabs) receives two kinds of environment values automatically:

1. **Typed coordinators** — `@Environment(HomeCoordinator.self)`: the owning coordinator *and every ancestor* up the parent chain (each injectable unless opted out).
2. **`\.destination`** — metadata about how the current screen was reached (root / push / sheet / full-screen cover and which `Destinations` case).

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
- `references/destination.md`: Use when a view adapts to how it was presented — back-chevron vs Close button or layout differences per route. Covers current `Destination` metadata, the `routeType` vs `presentationType` distinction, `meta` matching, the adaptive top-bar pattern, and migration from deprecated sheet configuration metadata.
- `references/previews.md`: Use when writing `#Preview` for any view or coordinator in a Scaffolding project. Covers injecting coordinators manually, why isolated views receive default destination metadata, and how to seed mid-flow preview states.

The same caveat applies in tests, where no view is rendered at all: use the `scaffolding-testing` skill for unit-testing coordinators.
