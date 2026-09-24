# Async navigation — suspend until dismissal

These APIs run on `@MainActor`. Standalone `awaiting:` calls suspend until the
destination leaves the hierarchy (pop, swipe, `dismissModal`,
`dismissCoordinator`, root swap). Combined `expecting:` + `awaiting:` calls
return the child immediately and an async closure that waits for that removal.

## `routeAndWait(to:)` — flows only

Push and suspend until the screen is popped or otherwise removed:

```swift
await routeAndWait(to: .picker)
// Waiting ended; prefer awaiting: Value.self when completion needs a value.
applySelection()
```

## Wait-only presentation — all four coordinator types

Present a modal and suspend until it is dismissed:

```swift
_ = await present(.onboarding, as: .fullScreenCover, awaiting: Void.self)
// Dismissal alone does not prove onboarding completed.
```

`presentAndWait` is deprecated; use `awaiting: Void.self` instead.

## `route(to:awaiting:)` / `present(_:as:awaiting:)` — a typed result

Suspends until removal and returns the value the child coordinator handed back
via `dismissCoordinator(returning:)`, or a view supplied through
`@Environment(\.destination).dismiss(returning:)`. Closing without a result
yields `nil`:

```swift
// Presenter
func connectAccount() async {
    guard let token = await present(.login, awaiting: AuthToken.self) else {
        return                    // no result (dismissal, task cancellation, or mismatch)
    }
    session.store(token)
}

// Presented LoginCoordinator
func submit() {
    dismissCoordinator(returning: AuthToken(...))
}
```

A result of the wrong type also resumes with `nil` — keep the `awaiting:` type and the `returning:` type in sync.

## `expecting:` + `awaiting:` — child now, result later

Use the combined overload when you need to configure the child before waiting:

```swift
let (picker, result) = route(
    to: .picker, expecting: PickerCoordinator.self, awaiting: Item.self
)
picker?.route(to: .favorites)
let item = await result()

let login = present(
    .login, as: .sheet, expecting: LoginCoordinator.self, awaiting: AuthToken.self
)
login.coordinator?.route(to: .signUp)
let token = await login.result()
```

The call is synchronous and returns
`(coordinator: T?, result: @MainActor () async -> Result?)`. Only `result()`
suspends. `present` supports flow, root, tab, and split coordinators.

- A view-only route or a child type mismatch makes `coordinator` nil without
  dropping its result channel.
- If `.distinct` skips navigation, the tuple has a nil child and a closure
  that returns `nil` immediately; it does not wait on the existing route.
- A result delivered before waiting remains available. Repeated calls to
  `result()` observe the same destination and do not navigate again.
- No task starts automatically. Cancelling the task that calls `result()`
  returns `nil` for that wait, leaving the UI and other waiters in place.
- A task cancelled before navigation creates no destination. `Void.self`
  remains the wait-only result type.

## Notes

- `policy:` works as elsewhere; when `.distinct` skips the navigation, the call returns immediately (`nil` for `awaiting:`).
- These APIs take no `onDismiss:` — the resumption *is* the dismissal signal.
- Standalone `awaiting:` calls and the combined tuple's result closure both
  support cancellation without dismissing the destination.
- Call them from `@MainActor` async contexts (a `Task` in a coordinator method, `.task` in a view). Typical shape:

```swift
func startExport() {
    Task {
        guard let format = await present(.formatPicker, awaiting: ExportFormat.self) else { return }
        await export(as: format)
    }
}
```

## Animation scopes

All four families expose `setTransitionAnimation(_:)`. Use
`withNavigationTransaction(animation: .disabled) { ... }` to suppress animation
across a synchronous chain, or `.custom(.easeInOut)` for a shared animation.
Scopes nest, restore on return/throw, and do not carry into new tasks.
