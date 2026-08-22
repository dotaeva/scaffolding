# Split Views on iPad and Mac

Build master–detail interfaces with ``SplitCoordinatable`` — a
`NavigationSplitView` whose columns are coordinator-owned destinations.

## Overview

A ``SplitCoordinatable`` wraps a `NavigationSplitView`: a sidebar column,
an optional middle content column, and a detail column. Each column shows
one destination — a plain view or a child coordinator.

![A split view's three columns and the call that replaces each one.](diagram-columns)

Column assignment lives in the ``SplitColumns`` initializer, so route
functions keep the ordinary auto-tracked return types:

```swift
@MainActor @Observable @Scaffoldable
final class LibraryCoordinator: @MainActor SplitCoordinatable {
    var columns = SplitColumns<LibraryCoordinator>(
        sidebar: .sidebar,
        detail: .placeholder          // shown before any selection
    )

    private(set) var selectedPlanetId: Int?

    func sidebar() -> some View { SidebarList() }
    func placeholder() -> some View { ContentUnavailableView.search }
    func planet(id: Int) -> any Coordinatable { PlanetFlowCoordinator(id: id) }

    func select(_ planet: Planet) {
        guard selectedPlanetId != planet.id else { return }
        selectedPlanetId = planet.id
        setDetail(.planet(id: planet.id))
    }
}
```

A child ``FlowCoordinatable`` placed in a column builds its own
`NavigationStack` there — exactly the composition SwiftUI expects inside
a split-view column — so pushes, pops, and modals inside a column are
ordinary flow calls. Compact width is free: `NavigationSplitView`
collapses to a single stack on iPhone, and because all state lives on the
coordinator, nothing is lost when the size class changes.

![The same coordinator tree on iPad and iPhone.](split-devices)

The same coordinator tree also renders natively on macOS — the Landmarks
example ships as an iPad, iPhone, and macOS app from one target:

![The Landmarks example on Mac, iPad, and iPhone.](landmarks-devices)

## Columns replace, they don't push

``SplitCoordinatable/setDetail(_:policy:)``,
``SplitCoordinatable/setContent(_:policy:)``, and
``SplitCoordinatable/setSidebar(_:policy:)`` replace the column like a
root swap: the previous destination's `onDismiss` (and any awaiting
continuation) fires exactly once, and a child coordinator loses its
pushed state.

Guard re-selection on your own domain state, as in the example above.
``RoutePolicy/distinct`` compares case identity only — it cannot tell
`.planet(id: 1)` from `.planet(id: 2)` — so it only works as a
re-selection guard when each selectable destination is its own case.

Selection *highlight* is view chrome: use a native `List(selection:)` in
the sidebar, synced both ways with the coordinator's domain state.

## Two or three columns, at runtime

The three-column form is `SplitColumns(sidebar:content:detail:)` —
sidebar → content → detail, the classic Mail shape. The content column is
dynamic: ``SplitCoordinatable/setContent(_:policy:)`` installs it on a
two-column split (the container swaps to the three-column form) and
``SplitCoordinatable/removeContent()`` drops it again.

## Visibility

- ``SplitCoordinatable/setColumnVisibility(_:)`` drives the columns
  programmatically; interactive changes (the sidebar toggle, edge swipes)
  write back into ``SplitCoordinatable/columnVisibility``.
- ``SplitCoordinatable/toggleSidebar()`` hides the sidebar with
  `.detailOnly` when ``SplitCoordinatable/isSidebarVisible``, restores
  `.all` otherwise — wire it to a toolbar button or a macOS menu command.
- ``SplitCoordinatable/setPreferredCompactColumn(_:)`` steers which
  column the collapsed (compact-width) form shows — useful when a deep
  link should land on the detail.

## Modals and shared chrome

``SplitCoordinatable/present(_:as:policy:onDismiss:)`` and the rest of
the modal family work exactly as on ``TabCoordinatable`` — the modal
renders above the whole split view. Cross-cutting chrome that the
underlying `NavigationSplitView` should carry — `searchable`, an
`inspector`, overlays — belongs in `customize(_:)`, which wraps the
generated split view.

## Placement rule

A `SplitCoordinatable` must never live inside a ``FlowCoordinatable`` —
SwiftUI does not support `NavigationSplitView` inside a
`NavigationStack`, and Scaffolding logs a critical error if you try.
Legal hosts: a ``RootCoordinatable`` root, a ``TabCoordinatable`` tab, or
a modal presentation.

## Testing

The orientation surface extends to columns:
``SplitCoordinatable/sidebarDestination``,
``SplitCoordinatable/contentDestination``,
``SplitCoordinatable/detailDestination``, and
``SplitCoordinatable/isDetail(_:)`` read the current columns, and
``HierarchyRole/column(_:)`` addresses them in whole-tree assertions:

```swift
let split = LibraryCoordinator().activated()
split.select(.mars)

#expect(split.isDetail(.planet))
#expect(split.hierarchyContains(LibraryCoordinator.self, .planet, as: .column(.detail)))
```

Views can read `@Environment(\.destination).column` to know which column
they render in.

## Topics

### Tutorials

- <doc:SplitViewApps>

### Split-view coordinators

- ``SplitCoordinatable``
- ``SplitColumns``
- ``AnySplitColumns``
- ``SplitColumn``
