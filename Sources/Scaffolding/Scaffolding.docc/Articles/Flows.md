# Building Flows

Push and pop screens, host child flows, and change a flow's root.

## Overview

A ``FlowCoordinatable`` owns a ``FlowStack``: one root destination and the
entries above it. It renders a `NavigationStack` unless it is pushed into
another flow, in which case it shares that flow's stack.

```swift
@MainActor @Observable @Scaffoldable
final class HomeCoordinator: @MainActor FlowCoordinatable {
    var stack = FlowStack<HomeCoordinator>(root: .home)

    func home() -> some View { HomeView() }
    func detail(id: Int) -> some View { DetailView(id: id) }
    func settings() -> any Coordinatable { SettingsCoordinator() }
}
```

## Push and pop

```swift
route(to: .detail(id: 42))      // push
pop()                           // remove the last entry
pop(2)                          // remove up to two, stopping at the root
popToRoot()                     // remove every push and modal
popToFirst(.detail)             // return to the first matching case
```

`pop()` removes the last stored entry, which may be a modal. On an empty stack
it dismisses the whole coordinator. Use `dismissPresentedModal()` when the
intent is to close a modal.

## Host a child flow

Return `any Coordinatable` from a route. How you open it decides the stack:

| Call | Child's stack |
|---|---|
| `route(to: .settings)` | Shares this flow's stack; Back walks through both |
| `present(.settings)` | Its own stack inside the sheet |

Inside the child, `pop()` walks its own entries and `dismissCoordinator()`
removes the whole child. Get a handle while navigating with
`route(to: .settings, expecting: SettingsCoordinator.self)`.

## Start deeper than the root

Seed the path in the initializer — for a preview, a test, or a resume entry:

```swift
var stack = FlowStack<HomeCoordinator>(root: .home, pushing: [.detail(id: 42)])
```

## Replace the root or the top screen

- `setRoot(_:)` installs a new root and clears every push and modal. It
  builds a fresh destination even for the same case.
- To replace only the top pushed screen, pop and route as two steps, and only
  when no modal is queued:

```swift
func showNext(id: Int) {
    guard !isPresentingModal else { return }
    if depth > 0 { pop() }
    route(to: .detail(id: id))
}
```

## Guard duplicate pushes

Use `.distinct` to absorb repeated taps while a detail screen is on top:

<!-- checked-swift: distinct-push -->
```swift
route(to: .detail(id: 42), policy: .distinct)
```

The policy checks the current top pushed destination, falling back to the root.
After returning to `.home`, the same detail can open again. Associated values
are ignored: `.detail(id: 1)` also blocks `.detail(id: 2)`. Use `.always` if
different records should stack. A record-specific guard must follow the live
destination's lifetime; caching only the last opened ID leaves stale state
after a pop, a back gesture, or restoration.

## API

| Intent | Method |
|---|---|
| Push | `route(to:policy:)`, plus `expecting:` and `awaiting:` overloads |
| Pop | `pop()`, `pop(_:)`, `popToRoot()`, `popToFirst(_:)`, `popToLast(_:)` |
| Replace the root | `setRoot(_:animation:)`, `setRoot(_:animation:expecting:)` |
| Present | `present(_:as:policy:)`; see <doc:ModalsAndResults> |
| Pushed count and top case (modals excluded) | `depth`, `topDestination` |
| Entries matching a case (root excluded, modals included) | `isInStack(_:)`, `count(of:)` |
| Default animation | `setTransitionAnimation(_:)` |

## Rules

- Never add a `NavigationStack` inside a route view or `customize(_:)`.
- Never push a ``SplitCoordinatable`` or make it a flow's root.
- Initialize `stack` as a `var` and seed it through `FlowStack(root:pushing:)`;
  never replace a live stack.

## See Also

- <doc:Essentials>
- <doc:ModalsAndResults>
- <doc:DeepLinking>
