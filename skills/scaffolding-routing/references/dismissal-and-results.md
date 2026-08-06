# Dismissal semantics and result delivery

## `dismissCoordinator()` — remove the *whole* coordinator

Called on the coordinator being removed. It pops the entire coordinator off its parent — not a screen:

- Presented as a sheet/cover → closes the modal.
- Pushed child coordinator → removes the child **and everything pushed after it**.
- Root of a parent flow's stack → dismisses the parent flow itself.
- Tab child → **cannot be dismissed**; logs a critical warning, does nothing.

To close a single screen use `pop()` (or `@Environment(\.dismiss)` in the view). The two are not interchangeable:

```swift
// ❌ Dismisses the entire coordinator/flow.
Button("Back") { coordinator.dismissCoordinator() }

// ✅ Pops one screen.
Button("Back") { coordinator.pop() }
```

## `onDismiss` — exactly once, every path

Every `route`/`present` accepts `onDismiss:`. It fires **exactly once** no matter how the destination is removed: pop, `popToRoot`, `popToFirst/Last`, back swipe, sheet swipe, `dismissModal`, `setRoot` tearing the stack down, or the coordinator being dismissed. Removals caused by a root swap are cancellations but still fire `onDismiss` — don't assume it means "user completed the screen"; it means "the destination is gone".

## Result delivery pattern 1 — constructor callback

The presenter installs a callback when constructing the child (route-function parameters become enum payloads, so closures ride along):

```swift
// Presenter (AppCoordinator)
func login(onComplete: @escaping @MainActor (AuthToken) -> Void) -> any Coordinatable {
    LoginCoordinator(onComplete: onComplete)
}

func startLogin() {
    present(.login(onComplete: { [weak self] token in
        self?.session = token
    }), as: .sheet)
}

// Inside LoginCoordinator, when the user finishes:
func submit() {
    onComplete(AuthToken(...))   // deliver result
    dismissCoordinator()         // then dismiss self
}
```

The presenter never observes the child's state; the child hands the result through the closure it was constructed with, then dismisses itself. Note: closure payloads make the `Destinations` case non-`Codable`, so they're incompatible with `@Scaffoldable(codable: true)` state restoration.

## Result delivery pattern 2 — `awaiting:` + `dismissCoordinator(returning:)`

For async call sites, skip the callback plumbing entirely:

```swift
// Presenter — suspends until the modal is gone.
guard let token = await present(.login, awaiting: AuthToken.self) else {
    return   // user backed out (swipe, dismissModal, plain dismissCoordinator)
}
session.store(token)

// Inside LoginCoordinator
dismissCoordinator(returning: AuthToken(...))
```

Any dismissal *without* `returning:` (or with a value of the wrong type) resumes the presenter with `nil` — cancellation is handled for free. See `async-navigation.md` for the full await family.

## Choosing

- Fire-and-forget flows, or results consumed in non-async contexts → constructor callback.
- Linear "ask the user, then continue" logic in async code → `awaiting:`.
- Both compose with `Codable` restoration only if payloads stay `Codable` (the `awaiting:` pattern keeps cases payload-free, which helps).
