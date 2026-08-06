# Push and pop

## `route(to:)` — push only

```swift
@discardableResult
func route(to destination: Destinations,
           policy: RoutePolicy = .always,
           onDismiss: @escaping @MainActor () -> Void = { }) -> Self
```

Pushes onto the flow's stack. There is **no `as:` parameter** — presenting modally is `present(_:as:)`. `onDismiss` fires exactly once when the destination leaves the stack by any path (pop, back swipe, root swap, coordinator dismissal).

```swift
coordinator.route(to: .detail(item: planet))
coordinator.route(to: .detail(item: planet), policy: .distinct)   // double-tap guard
coordinator.route(to: .editor) { print("editor closed") }
```

### `RoutePolicy`

- `.always` (default) — apply unconditionally. Use when consecutive same-case pushes are intentional (e.g. recursive folder navigation).
- `.distinct` — skip the push when the same destination **case** is already on top of the stack (for modals: already presented). Comparison uses `Destinations.Meta` — the case name only, **not** associated values. Two pushes of `.detail(item:)` with different items still count as duplicates.

## Pop variants — not interchangeable

| Call | Behavior |
|---|---|
| `pop()` | Removes the top destination. **When the stack is empty, dismisses the whole coordinator from its parent.** |
| `pop(3)` | Removes up to N destinations, always **stopping at the root** — never dismisses the coordinator. |
| `popToRoot()` | Removes everything above the root. |
| `popToFirst(.detail)` | Pops back to the **first** occurrence of the case (by `Meta`). Matching the root pops to root. No match → no-op. |
| `popToLast(.detail)` | Same, but the **last** occurrence. |

Every removed destination's `onDismiss` fires exactly once. Prefer `dismissModal()` over `pop()` for closing modals — `pop()` removes whatever is last (and can dismiss the coordinator), while `dismissModal()` only ever touches modals and is a safe no-op otherwise.

Inside a view, prefer SwiftUI's `@Environment(\.dismiss)` for a plain "back" button — it works for both pops and modal dismissal because Scaffolding wraps `NavigationStack`.

## `replaceLast(with:)`

Replaces the topmost **pushed** destination; the replaced one's `onDismiss` fires. Back then skips the replaced screen — loading→result transitions, wizard steps that shouldn't be revisited:

```swift
coordinator.replaceLast(with: .paymentResult(outcome: outcome))
```

When nothing is pushed it behaves like `route(to:)` — the root is never replaced (use `setRoot` for that).

## `setRoot` on a flow

```swift
flow.setRoot(.dashboard)                       // clears all pushed destinations first
flow.setRoot(.dashboard, animation: .snappy)
```

Pushed destinations are invalid once the root changes, so they are removed (resolving their `onDismiss`) before the swap.

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

All mutating calls return `self` (`@discardableResult`), so sequences chain:

```swift
coordinator.popToRoot().route(to: .settings)
```

Typed overloads that resolve child coordinators (`route(to:) { (child: T) in }`, `route(to:expecting:)`) are covered in `deep-linking.md`.
