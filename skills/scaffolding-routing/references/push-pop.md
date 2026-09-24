# Push and pop

## `route(to:)` — push only

```swift
@discardableResult
func route(to destination: Destinations,
           policy: RoutePolicy = .always) -> Self
```

Pushes onto the flow's stack. There is **no `as:` parameter** — presenting modally is `present(_:as:)`. Awaiting calls resolve when the destination leaves by any path (pop, back swipe, root swap, coordinator dismissal). Legacy `onDismiss:` overloads are deprecated.

```swift
coordinator.route(to: .detail(item: planet))
coordinator.route(to: .detail(item: planet), policy: .distinct)   // double-tap guard
_ = await coordinator.route(to: .editor, awaiting: Void.self)
```

### `RoutePolicy`

- `.always` (default) — apply unconditionally. Use when consecutive same-case pushes are intentional (e.g. recursive folder navigation).
- `.distinct` — skip the push when the same destination **case** is already on top of the stack (for modals: an own request of that case already exists, including queued requests). Comparison uses `Destinations.Meta` — the case name only, **not** associated values. Two pushes of `.detail(item:)` with different items still count as duplicates.

## Pop variants — not interchangeable

| Call | Behavior |
|---|---|
| `pop()` | Removes the top destination. **When the stack is empty, dismisses the whole coordinator from its parent.** |
| `pop(3)` | Removes up to N destinations, always **stopping at the root** — never dismisses the coordinator. |
| `popToRoot()` | Removes everything above the root. |
| `popToFirst(.detail)` | Pops back to the **first** occurrence of the case (by `Meta`). Matching the root pops to root. No match → no-op. |
| `popToLast(.detail)` | Same, but the **last** occurrence. |

Each removal resolves its result once. Prefer `dismissPresentedModal()` for closing the front modal request. `dismissModal()` removes the latest own request, which may still be queued. Modal helpers never pop screens.

Inside a view, prefer SwiftUI's `@Environment(\.dismiss)` for a plain "back" button — it works for both pops and modal dismissal because Scaffolding wraps `NavigationStack`.

## `replaceLast` is deprecated

All `replaceLast` overloads remain only for compatibility and will be removed.
Do not generate new calls. For an explicit pushed-screen replacement when no
modal is queued, pop the existing push then route to the next destination.
Guard `depth > 0` if the flow might already be at its root. Use `setRoot(_:)`
when the intent is a new flow root. Pop and route resolve callbacks normally;
they are separate mutations, not an atomic replacement.

## `setRoot` on a flow

```swift
flow.setRoot(.dashboard)                       // clears pushed and modal destinations
flow.setRoot(.dashboard, animation: .snappy)
```

Pushed destinations are invalid once the root changes, so they are removed (resolving their awaiting calls without a result) before the swap.

## Stack queries

```swift
coordinator.depth                 // pushed count above root (modals excluded)
coordinator.topDestination        // Meta of top pushed destination, or root's meta
coordinator.isInStack(.detail)    // Bool (root not counted)
coordinator.count(of: .detail)    // occurrences among pushed + presented
coordinator.isPresentingModal     // Bool
```

## Hierarchy orientation (any coordinator type)

```swift
coordinator.routeType                    // how THIS coordinator was presented:
                                         // .root / .push / .sheet / .fullScreenCover
coordinator.routeType.isModal            // sheet or cover
coordinator.ancestor(ofType: AppCoordinator.self)  // its nearest ancestor of that type, or nil
coordinator.hierarchyRoot                // topmost coordinator of the tree
```

`routeType` answers "was I pushed, presented, or am I a root/tab child" — useful for dismissal decisions (`routeType.isModal ? dismissModal-style close button : back`). It is the coordinator-side counterpart of the view-side `@Environment(\.destination).routeType`, and the two can differ for the same screen: a view pushed inside a sheet-presented flow reads `.push` while its flow reads `.sheet`.

`ancestor(ofType:)` is how a coordinator reaches *up* (e.g. `ancestor(ofType: AppCoordinator.self)?.setRoot(.unauthenticated)`); views instead read ancestors straight from the environment. When routing misbehaves, dump the live tree from anywhere: `print(coordinator.hierarchyRoot.debugHierarchy())`.

## Return values and chaining

Plain synchronous push/pop methods return `self` (`@discardableResult`), so sequences chain. Typed overloads return children and awaiting overloads return results:

```swift
coordinator.popToRoot().route(to: .settings)
```

Typed overloads that resolve child coordinators (`route(to:expecting:)`) are covered in `deep-linking.md`.
