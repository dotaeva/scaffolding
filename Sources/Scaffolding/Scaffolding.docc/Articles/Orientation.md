# Inspecting the Hierarchy

Find which coordinator to call, query where a screen sits, and print the
whole tree.

## Overview

Don't guess in a deep tree of roots, tabs, flows, and modals. Each question
below has a direct query. Print the tree before changing misbehaving routing.

## Find the coordinator to call

| From | Use |
|---|---|
| A view — its owner or any ancestor | `@Environment(HomeCoordinator.self)` |
| A coordinator — upward | ``Coordinatable/ancestor(ofType:)`` in one module; an injected capability across packages |
| A coordinator — downward | `expecting:` overloads, never stored references |
| Anywhere — the top | ``Coordinatable/hierarchyRoot`` |

Prefer the nearest coordinator. Reach an ancestor only for actions it owns,
such as a root swap or tab switch. See <doc:MonolithicApps> and
<doc:ModularApps>.

## Query the current state

| Question | Query |
|---|---|
| How was this coordinator presented? | ``Coordinatable/routeType``; ``DestinationType/isModal`` groups sheet and cover |
| How does this screen appear? | `@Environment(\.destination)` — see <doc:Essentials#Use-the-destination-value> |
| How many screens are pushed, and which is on top? | ``FlowCoordinatable/depth``, ``FlowCoordinatable/topDestination`` (modals excluded) |
| Is a case in the flow, and how often? | ``FlowCoordinatable/isInStack(_:)``, ``FlowCoordinatable/count(of:)`` (root excluded, modals included) |
| Which root is showing? | ``RootCoordinatable/isRoot(_:)`` |
| Which tabs exist, and which is selected? | ``TabCoordinatable/isInTabItems(_:)``, `selectedTabDestination`, `selectedTabIndex` |
| What is in each column? | ``SplitCoordinatable/sidebarDestination``, ``SplitCoordinatable/contentDestination``, ``SplitCoordinatable/detailDestination`` |
| Any own modal requests? | `isPresentingModal` (includes queued), `pendingModalCount` |

The coordinator's `routeType` and a screen's `routeType` answer different
questions. In a flow presented as a sheet, the coordinator reads `.sheet`, its
root screen reads `.root`, and a pushed screen reads `.push`.

## Print the tree

```swift
print(coordinator.hierarchyRoot.debugHierarchy())
```

```
AppCoordinator [root]
  root .authenticated → MainTabCoordinator [tab]
    tab[0]* .home → HomeCoordinator [flow]
      root .home
      push .detail
      sheet .settings → SettingsCoordinator [flow]
        root .settings
```

``Coordinatable/debugHierarchy()`` returns this string.
``Coordinatable/hierarchySnapshot()`` returns the same tree as
``HierarchyNode`` values (`role`, `meta`, `coordinator`, `children`) for
tests and debug UIs.

## Rules

- Neither snapshot runs route factories. A child not yet created reports no
  coordinator.
- Neither resolves an untouched container: a coordinator that has not
  rendered or navigated can print empty. Call `activated()` in tests to
  resolve the initial hierarchy.

## See Also

- <doc:Essentials>
- <doc:DeepLinking>
- <doc:TestingCoordinators>
