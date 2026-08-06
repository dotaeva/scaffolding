# Async navigation — suspend until dismissal

All of these are `@MainActor` async methods on coordinators. The suspension resumes **exactly once**, however the destination leaves the hierarchy (pop, swipe, `dismissModal`, `dismissCoordinator`, root swap).

## `routeAndWait(to:)` — flows only

Push and suspend until the screen is popped or otherwise removed:

```swift
await routeAndWait(to: .picker)
// picker is gone — read whatever state it wrote
applySelection()
```

## `presentAndWait(_:as:)` — flow, tab, and root coordinators

Present a modal and suspend until it is dismissed:

```swift
await presentAndWait(.onboarding, as: .fullScreenCover)
markOnboardingSeen()
```

## `present(_:as:awaiting:)` — modal with a typed result

Suspends until dismissal and returns the value the presented coordinator handed back via `dismissCoordinator(returning:)`; every other dismissal path yields `nil`:

```swift
// Presenter
func connectAccount() async {
    guard let token = await present(.login, awaiting: AuthToken.self) else {
        return                    // user cancelled
    }
    session.store(token)
}

// Presented LoginCoordinator
func submit() {
    dismissCoordinator(returning: AuthToken(...))
}
```

A result of the wrong type also resumes with `nil` — keep the `awaiting:` type and the `returning:` type in sync.

## Notes

- `policy:` works as elsewhere; when `.distinct` skips the navigation, the call returns immediately (`nil` for `awaiting:`).
- These APIs take no `onDismiss:` — the resumption *is* the dismissal signal.
- Call them from `@MainActor` async contexts (a `Task` in a coordinator method, `.task` in a view). Typical shape:

```swift
func startExport() {
    Task {
        guard let format = await present(.formatPicker, awaiting: ExportFormat.self) else { return }
        await export(as: format)
    }
}
```
