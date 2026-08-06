# Modals — `present(_:as:)` and dismissal

## Presenting

Available on **all three** coordinator types. Flow modals live on the flow's stack; tab/root modals render above the `TabView` / current root.

```swift
@discardableResult
func present(_ destination: Destinations,
             as type: ModalPresentationType = .sheet,
             policy: RoutePolicy = .always,
             onDismiss: @escaping @MainActor () -> Void = { }) -> Self
```

```swift
coordinator.present(.settings)                          // sheet (default)
coordinator.present(.onboarding, as: .fullScreenCover)
coordinator.present(.settings, policy: .distinct)       // skip if the case is already presented
coordinator.present(.filters, onDismiss: { self.reload() })
```

`.distinct` compares by `Destinations.Meta` (case name), not associated values.

## Presenter-side sheet configuration

The **presenter** decides how the sheet appears — the destination view stays ignorant. Same destination, different chrome per call site:

```swift
coordinator.present(.settings, as: .sheet(detents: [.medium, .large]))
coordinator.present(.wizard, as: .sheet(
    detents: [.large],
    dragIndicator: .hidden,
    interactiveDismissDisabled: true   // blocks swipe-down; programmatic dismissal still works
))
```

Empty `detents` means the system default. The presented view can read the applied configuration from `@Environment(\.destination).modalConfiguration` (see `scaffolding-environment`).

`fullScreenCover` is not rendered on macOS — prefer `.sheet` for cross-platform code.

## View-only vs sub-flow modals

- **Single screen** (confirmation, info, simple form): stay native — `.sheet(item:)` with local `@State` in the view. No `Destinations` case needed.
- **Sub-flow** (multiple steps, pushes, dismiss-with-result): `present(_:as:)` with a route that returns a child coordinator.
- A `some View` route may also be presented modally (e.g. a what's-new page owned by the flow) — it just has no coordinator of its own, so only the presenter can close it programmatically, via `dismissModal()`.

## Dismissing from the presenter — `dismissModal()` / `dismissAllModals()`

Available on every coordinator type:

```swift
coordinator.dismissModal()        // removes the MOST RECENT modal; onDismiss fires once
coordinator.dismissAllModals()    // removes every modal on THIS coordinator
```

- Equivalent to the user swiping the sheet away — `onDismiss` fires exactly once.
- On a flow, only modals are touched; pushed destinations stay. Prefer this over `pop()` for closing modals: it's a safe no-op when nothing is presented, whereas `pop()` removes whatever is topmost and dismisses the whole coordinator on an empty stack.
- Neither call reaches into modals presented by *other* coordinators deeper in the tree.
- The presented coordinator closing **itself** uses `dismissCoordinator()` instead (see `dismissal-and-results.md`).

```swift
appCoordinator.present(.whatsNew)     // view-only route
// … later, presenter decides it's done:
appCoordinator.dismissModal()
```

## Constraints

- **One modal at a time per layer.** Presenting while a modal is up logs a runtime warning; the second modal appears after the first is dismissed. Design flows so a presented coordinator presents its *own* children (nesting works) rather than stacking siblings.
- `isPresentingModal` reports whether *this* coordinator currently has a modal up.
- Inside the presented view, SwiftUI's `@Environment(\.dismiss)` also works for a close button — including in reusable components that don't know the coordinator type.
