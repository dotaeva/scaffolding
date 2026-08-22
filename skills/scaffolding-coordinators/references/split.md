# SplitCoordinatable — NavigationSplitView coordinator (iPad / Mac)

A `SplitCoordinatable` wraps a `NavigationSplitView`: a sidebar column, an optional content column, and a detail column. Each column shows one destination — a plain view or a child coordinator. Use it for master–detail interfaces; it is the only sanctioned way to get a split view in a Scaffolding app (never hand-roll `NavigationSplitView` in a view).

## Defining one

Column assignment lives in the `SplitColumns` initializer, not in the route functions — routes keep the ordinary auto-tracked return types (`some View` / `any Coordinatable`; tab tuples don't apply here).

```swift
@MainActor @Observable @Scaffoldable
final class LibraryCoordinator: @MainActor SplitCoordinatable {
    var columns = SplitColumns<LibraryCoordinator>(
        sidebar: .sidebar,
        detail: .placeholder,                 // shown before any selection
        visibility: .automatic,               // NavigationSplitViewVisibility
        preferredCompactColumn: .sidebar      // collapsed (iPhone) start column
    )

    // Domain state, not navigation state: which planet is showing.
    private(set) var selectedPlanetId: Int?

    func sidebar() -> some View { SidebarList() }
    func placeholder() -> some View { ContentUnavailableView.search }
    func planet(id: Int) -> any Coordinatable { PlanetFlowCoordinator(id: id) }

    // Sidebar rows call this. Guard re-selection on domain state — NOT
    // `policy: .distinct`: every planet is the same `.planet` case, and
    // `.distinct` compares case identity only (associated values are
    // ignored), so it would also swallow switches between planets.
    func select(_ planet: Planet) {
        guard selectedPlanetId != planet.id else { return }
        selectedPlanetId = planet.id
        setDetail(.planet(id: planet.id))
    }
}
```

Three-column form: `SplitColumns(sidebar:content:detail:)` — sidebar → content → detail, the Mail-style shape. The content column is also dynamic: `setContent(_:)` on a two-column split installs it (the rendered container swaps to `NavigationSplitView`'s three-column form) and `removeContent()` drops it again, resolving the removed destination's dismissal once.

## Column semantics

- `setDetail(_:policy:)` / `setContent(_:policy:)` / `setSidebar(_:policy:)` **replace** the column, like a `setRoot` — the previous destination is torn down (its `onDismiss`/continuations fire once, a child coordinator loses its pushed state). `.distinct` makes re-selection a no-op, but it compares **case identity only** — associated values are ignored, so with one parameterized case (`.planet(id:)`) guard on domain state as above; use `.distinct` only when each selectable destination is its own case.
- All three have the typed trailing-closure and `expecting:` overloads for deep links: `split.setDetail(.planet(id: 4)) { (flow: PlanetFlowCoordinator) in flow.route(to: .moon(id: 2)) }`.
- A child `FlowCoordinatable` in a column builds its own `NavigationStack` there — exactly the composition SwiftUI expects inside a split-view column. Pushes, pops, and modals inside the column are ordinary flow calls.
- Column children cannot `dismissCoordinator()` — columns are structural, like tabs (a critical error is logged). Replace the column instead.
- Selection *highlight* stays in the sidebar view; the coordinator owns only which destination the detail column shows. Use a native `List(selection:)` synced with the coordinator's domain state. Platform caveat: the iPad portrait **overlay** sidebar does not auto-dismiss after a selection when the detail is coordinator-driven (SwiftUI only auto-hides it for selection-bound details) — the user taps the detail area to close it, or hide it with `setColumnVisibility(.detailOnly)` when you know the sidebar is overlaid.

## Visibility and compact width

- `setColumnVisibility(.detailOnly / .doubleColumn / .all / .automatic)` drives the columns programmatically; interactive changes (sidebar toggle, edge swipe) write back into `columnVisibility`.
- `toggleSidebar()` hides the sidebar with `.detailOnly` when `isSidebarVisible`, restores `.all` otherwise — animated; wire it to a toolbar button, macOS menu command, or keyboard shortcut (SwiftUI's own sidebar button and `SidebarCommands()` on macOS do the same thing natively).
- `isSidebarVisible` derives sidebar visibility from `columnVisibility` (`.detailOnly` hides it; `.doubleColumn` hides it only on a three-column split) — drive show/hide chrome from it rather than re-deriving the rule.
- `setPreferredCompactColumn(_:)` steers which column the collapsed (compact-width) form shows.
- Compact collapse is free: state lives on the coordinator, so nothing is lost when the size class changes.

## Known issue — iOS 27 beta runtime

On the iOS 27 beta (fine on iOS 26), SwiftUI re-evaluates a view's environment in detached contexts — a detail column replaced by a deep link — with injected coordinators absent, so a non-optional `@Environment(SomeCoordinator.self)` in an affected view traps. Workaround: in views reachable through those transitions, read the coordinator optionally (`@Environment(X.self) private var coordinator: X?`) and init-inject the data the view renders. A live user-driven push is unaffected. (Scaffolding itself works around the related beta issue of `NavigationStack` dropping a pre-seeded path: the path binding activates one frame after the stack mounts, so deep-link chains keep their pushed state.)

## macOS notes

- Full-screen covers don't exist on macOS: `present(_:as: .fullScreenCover)` renders as a **sheet** there (state still reports `.fullScreenCover`).
- `SidebarCommands()` in the app's `.commands` gives the standard sidebar menu item/shortcut; `toggleSidebar()` is there for custom menu commands or toolbar buttons.

## Modals

`present(_:as:policy:onDismiss:)`, the typed/`expecting:` overloads, `presentAndWait`, `present(_:awaiting:)`, `dismissModal()`, and `isPresentingModal` all work exactly as on `TabCoordinatable` — the modal renders above the whole split view.

## Placement rule (hard)

A `SplitCoordinatable` must never live inside a `FlowCoordinatable` — SwiftUI does not support `NavigationSplitView` inside a `NavigationStack`, and Scaffolding logs a critical error if you try. Legal hosts: a `RootCoordinatable` root, a `TabCoordinatable` tab, or a modal presentation.

## Introspection and testing

- `sidebarDestination` / `contentDestination` / `detailDestination` return the current column's `Destinations.Meta`; `isDetail(.planet)` is the common assertion.
- `debugHierarchy()` renders the coordinator as `[split]` with `sidebar .sidebar` / `detail .planet → PlanetFlowCoordinator [flow]` lines.
- `hierarchySnapshot()` / `hierarchyContains` use the `.column(.sidebar / .content / .detail)` role: `#expect(app.hierarchyContains(LibraryCoordinator.self, .planet, as: .column(.detail)))`.
- Views can read `@Environment(\.destination).column` to know which column they render in.
- With `@Scaffoldable(codable: true)`, `captureNavigationState()` / `restoreNavigationState(from:)` round-trip all three columns, their children's state, and the column visibility.
