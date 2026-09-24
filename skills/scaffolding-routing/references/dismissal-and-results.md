# Dismissal and result delivery

## Remove one screen or the whole flow

`dismissCoordinator()` acts on the coordinator being removed:

| Placement | Effect |
|---|---|
| Sheet / cover | Closes that modal and preserves queued siblings |
| Pushed child | Removes the child and the destinations pushed after it |
| Root inside a flow or root wrapper | Dismisses through the enclosing branch |
| Tab or split-column child | No removal; these are structural destinations |
| Top-level coordinator | No-op; there is no parent |

Use `pop()` for a step within a flow, or native `@Environment(\.dismiss)` for a
view's ordinary Back action. `pop()` at an empty stack attempts to dismiss the
coordinator; `pop(_:)` stops at the root.

From the presenter, `dismissPresentedModal()` closes the front request in the
shared host queue. `dismissModal()` removes the latest own request even if it is
pending. See `modals.md` for ownership and pending cancellation.

## One result: prefer awaiting

```swift
// Presenter, in an async coordinator action:
guard let token = await present(.login, awaiting: AuthToken.self) else { return }
session.store(token)

// Child, when the whole flow has completed:
dismissCoordinator(returning: token)
```

A view-only destination uses `@Environment(\.destination)` and
`destination.dismiss(returning: value)`. This targets that exact route. A pushed
route removes the suffix above it; a child-flow root dismisses its enclosing
branch. Structural tabs, columns, and top-level roots cannot remove themselves.
A retained destination handle is inert after its route leaves.

Ordinary dismissal without a value returns nil. A result-type mismatch also
returns nil. Cancelling the waiting task returns nil while leaving the route in
place. Check `Task.isCancelled` after waiting when cancellation needs different
handling; a nil result alone does not identify the completion reason.

Removed branches detach before their awaiting calls resume, so callers can start
new navigation safely. Each destination resolves once. Deprecated `onDismiss:`
overloads follow the same removal lifecycle; do not generate new uses.

## Repeated updates: constructor callbacks

A child that reports several times before dismissal can receive a callback:

```swift
func editor(onChange: @escaping @MainActor (Draft) -> Void) -> any Coordinatable {
    EditorCoordinator(onChange: onChange)
}

func startEditing() {
    present(.editor(onChange: { [weak self] draft in
        self?.save(draft)
    }))
}
```

The child calls `onChange` as needed and eventually `dismissCoordinator()`.
The presenter does not observe the child's internal state. Callback route
payloads are incompatible with `@Scaffoldable(codable: true)`.

For non-async entry points that need one result, use a task or the combined
`expecting:` + `awaiting:` overload. See `async-navigation.md`.
