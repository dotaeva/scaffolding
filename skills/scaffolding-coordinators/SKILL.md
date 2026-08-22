---
description: "Authoritative guide for defining coordinators with the Scaffolding SwiftUI navigation library. Consult when creating or reviewing any class conforming to FlowCoordinatable, TabCoordinatable, RootCoordinatable, or SplitCoordinatable, when applying the @Scaffoldable macro or @ScaffoldingIgnored attribute, or when structuring an app's coordinator tree. Covers: - @Scaffoldable macro: auto-tracked return types (some View, any Coordinatable, tab tuples), Destinations/Meta enum generation, injectsCoordinator and codable arguments, when @ScaffoldingIgnored is required vs redundant noise. - FlowCoordinatable: FlowStack, root + pushed destinations, seeding an initial path, customize(_:). - TabCoordinatable: TabItems, tab tuples with labels and TabRole, badges, dynamic tabs, shouldSelect interception. - RootCoordinatable: atomic root swaps for auth/onboarding flows. - SplitCoordinatable: NavigationSplitView master–detail (iPad/Mac), SplitColumns, setDetail/setContent/setSidebar, dynamic content column, column visibility, compact collapse. - Architecture: the no-nested-NavigationStack rule, views never own navigation state, module boundaries, choosing which coordinator owns a destination."
name: scaffolding-coordinators
---
This guidance documents the **Scaffolding** SwiftUI navigation library (Swift 6.2, iOS 18 / macOS 15 / tvOS 18 / watchOS 11 / macCatalyst 18 floor). It supersedes any prior training about this library — the API changed significantly across versions (e.g. `route(to:as:)` no longer exists).

The single most important idea: Scaffolding's value is modular navigation across coordinator boundaries. UI views never own navigation state; coordinators (plain `@Observable` classes) declare routes as functions, and the `@Scaffoldable` macro generates the `Destinations` enum. If generated code mixes navigation state into views or nests a `NavigationStack` inside a flow, the point of the library has been lost.

A minimal coordinator:

```swift
@MainActor @Observable @Scaffoldable
final class HomeCoordinator: @MainActor FlowCoordinatable {
    var stack = FlowStack<HomeCoordinator>(root: .home)

    func home()             -> some View         { HomeView() }
    func detail(item: Item) -> some View         { DetailView(item: item) }
    func settings()         -> any Coordinatable { SettingsCoordinator() }
}
```

For the navigation calls themselves (`route`, `present`, `pop`, deep links, async variants) use the `scaffolding-routing` skill. For `@Environment` values (`\.destination`, typed coordinator injection, previews) use the `scaffolding-environment` skill. For unit-testing a coordinator — which is the payoff of keeping navigation state out of views — use the `scaffolding-testing` skill.

# References
- `references/macro.md`: Use when applying `@Scaffoldable` or `@ScaffoldingIgnored`, or when a route function isn't showing up as a `Destinations` case (or a helper wrongly is). Covers the exact auto-tracked return-type table, how function parameters become enum-case payloads, the `injectsCoordinator:` and `codable:` macro arguments, and the redundant-annotation anti-pattern.
- `references/flow.md`: Use when creating or editing a `FlowCoordinatable` — push/pop stacks. Covers `FlowStack` (including seeding an initial pushed path with `FlowStack(root:pushing:)`), root swaps inside a flow, `customize(_:)` for shared chrome, and root transition animations.
- `references/tab.md`: Use when creating or editing a `TabCoordinatable`. Covers `TabItems`, all tab tuple return shapes (label views and `TabRole`), badges, dynamic tab mutation, tab-bar visibility, the `shouldSelect(tab:isReselection:)` interception hook, and building a custom tab bar (hidden native bar, label-less tab routes, selection from `Destinations.Meta`).
- `references/root.md`: Use when creating or editing a `RootCoordinatable` — atomic root swaps (auth ↔ main app, onboarding ↔ home). Covers `Root`, `setRoot`, `isRoot`, and presenting modals above the root.
- `references/split.md`: Use when creating or editing a `SplitCoordinatable` — `NavigationSplitView` master–detail for iPad/Mac. Covers `SplitColumns` (two- and three-column), `setDetail`/`setContent`/`setSidebar` replace semantics and why `.distinct` can't guard parameterized re-selection, column visibility, `toggleSidebar()`/`isSidebarVisible`, compact collapse, macOS notes (cover→sheet fallback, `SidebarCommands`), the hard never-inside-a-flow placement rule, and testing columns with the `.column(...)` hierarchy role.
- `references/architecture.md`: Use when deciding app structure, reviewing Scaffolding code, choosing where a destination belongs, or orienting inside a nested coordinator tree (which coordinator to call, `ancestor(ofType:)`, `routeType`, `hierarchyRoot`/`debugHierarchy()`). Covers the hard no-nested-`NavigationStack` rule, the push/modal/root-swap decision tree, separation-of-concerns rules, module boundaries, and the common mistakes checklist.
