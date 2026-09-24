# Building Split Views

Build sidebar–detail interfaces whose columns are coordinator-owned
destinations.

## Overview

A ``SplitCoordinatable`` renders a `NavigationSplitView` with a sidebar, an
optional content column, and a detail column. Each column shows one view or
child coordinator. A child flow in a column gets its own stack, so pushes and
modals inside it are ordinary flow calls.

![A split coordinator owns sidebar, optional content, and detail. setDetail removes the old detail branch and installs a fresh flow while the other columns stay in place.](split-columns)

```swift
@MainActor @Observable @Scaffoldable
final class LibraryCoordinator: @MainActor SplitCoordinatable {
    var columns = SplitColumns<LibraryCoordinator>(
        sidebar: .sidebar,
        detail: .placeholder
    )

    private(set) var selectedPlanetID: Int?

    func sidebar() -> some View { SidebarList() }
    func placeholder() -> some View { ContentUnavailableView.search }
    func planet(id: Int) -> any Coordinatable { PlanetFlowCoordinator(id: id) }
}

extension LibraryCoordinator {
    func select(_ planet: Planet) {
        guard selectedPlanetID != planet.id else { return }
        selectedPlanetID = planet.id
        setDetail(.planet(id: planet.id))
    }
}
```

## Adapt to compact width

At compact width the split collapses to one stack. State lives on the
coordinator, so nothing is lost when the size class changes.
`setPreferredCompactColumn(_:)` chooses which column shows.

![Wide layouts show sidebar and detail side by side. Compact layouts use one navigation stack while preserving coordinator state.](split-adaptation)

## Replace columns

``SplitCoordinatable/setDetail(_:policy:)``,
``SplitCoordinatable/setContent(_:policy:)``, and
``SplitCoordinatable/setSidebar(_:policy:)`` remove the old column branch —
its waiters resolve with `nil` — and install a fresh one.

- Guard re-selection on domain identity, as `select(_:)` does above.
  ``RoutePolicy/distinct`` compares cases only, so `.planet(id: 1)` matches
  `.planet(id: 2)`.
- Keep selection highlight in a native `List(selection:)`, synced with the
  coordinator's state.
- `setContent(_:)` adds a middle column at runtime; `removeContent()` drops it.
- A detail change does not close an overlaid iPad sidebar. Call
  `setColumnVisibility(.detailOnly)` when your layout needs that.

## Add shared chrome

Modals presented from the split render above all columns. Put chrome for the
whole split — `searchable`, `inspector`, overlays — in `customize(_:)`.

## API

| Intent | Method |
|---|---|
| Replace a column | ``SplitCoordinatable/setSidebar(_:policy:)``, ``SplitCoordinatable/setContent(_:policy:)``, ``SplitCoordinatable/setDetail(_:policy:)``, plus `expecting:` overloads |
| Remove the middle column | ``SplitCoordinatable/removeContent()`` |
| Show or hide columns | ``SplitCoordinatable/setColumnVisibility(_:)``, ``SplitCoordinatable/toggleSidebar()`` |
| Choose the compact column | ``SplitCoordinatable/setPreferredCompactColumn(_:)`` |
| Read columns | ``SplitCoordinatable/sidebarDestination``, ``SplitCoordinatable/contentDestination``, ``SplitCoordinatable/detailDestination``, ``SplitCoordinatable/isDetail(_:)`` |
| Read visibility | ``SplitCoordinatable/columnVisibility``, ``SplitCoordinatable/isSidebarVisible`` |
| Default animation | ``SplitCoordinatable/setTransitionAnimation(_:)`` |

## Rules

- Never push a split or make it a flow's root: SwiftUI does not support a
  `NavigationSplitView` inside a `NavigationStack`, and Scaffolding logs a
  critical error. Host it as a root destination, a tab, or a modal.
- Column children are structural: replace the column instead of dismissing it.
- `@Environment(\.destination).column` is set on view routes placed directly
  in a column; screens inside a child flow read `nil`.

For a modular app that hosts the same features in tabs and columns, see
[Atlas](https://github.com/dotaeva/scaffolding/tree/main/Example/Atlas).

## See Also

- <doc:Essentials>
- <doc:Flows>
- <doc:DeepLinking>
