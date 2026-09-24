# Modals — `present(_:as:)` and dismissal

## Presenting

Available on **all four** coordinator types. Flow modals live on the flow's stack; tab/root/split modals render above the `TabView` / current root.

```swift
@discardableResult
func present(_ destination: Destinations,
             as type: ModalPresentationType = .sheet,
             policy: RoutePolicy = .always) -> Self
```

```swift
coordinator.present(.settings)                          // sheet (default)
coordinator.present(.onboarding, as: .fullScreenCover)
coordinator.present(.settings, policy: .distinct)       // skip if the case is already presented
_ = await coordinator.present(.filters, awaiting: Void.self)
reload()
```

`.distinct` compares by `Destinations.Meta` (case name), not associated values.

## Native SwiftUI sheet configuration

Use plain `.sheet` and apply native modifiers to the presented content. For a
view route, apply them inside the view or on the view returned by the route:

```swift
func filters() -> some View {
    FiltersView()
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(true)
}
```

For a child coordinator, apply modifiers to its container in `customize(_:)`
in an extension, so pushed screens share the configuration. Keep the route's
return type `any Coordinatable`; do not return the child's `.view` as a workaround.
Pass ordinary view/coordinator inputs if settings vary by caller. Provide a
completion or close action when disabling interactive dismissal.

The configured `.sheet(...)` factory, `SheetConfiguration`, and
`destination.modalConfiguration` are deprecated compatibility APIs. Existing
calls keep their behavior; native modifiers do not populate that metadata.
Omit `presentationDetents` for default sizing. When migrating, remove the
configured factory call so the legacy wrapper does not compete with modifiers.

On macOS `fullScreenCover` renders as a sheet while preserving its recorded route type.

## View-only vs sub-flow modals

- **Single screen** (confirmation, info, simple form): stay native — `.sheet(item:)` with local `@State` in the view. No `Destinations` case needed.
- **Sub-flow** (multiple steps, pushes, dismiss-with-result): `present(_:as:)` with a route that returns a child coordinator.
- A `some View` route may also be presented modally (e.g. a what's-new page owned by the flow) — it just has no coordinator of its own, and can close via `@Environment(\.destination).dismiss()` or the presenter's `dismissPresentedModal()`.

## Presenter-side dismissal and queues

Available on every coordinator type, including generic `C: Coordinatable`:

```swift
coordinator.dismissPresentedModal()  // closes the first request in presentation order
coordinator.dismissModal()           // removes the latest own request, even if still queued
coordinator.cancelPendingModals()    // preserves the front request; removes own pending ones
coordinator.dismissAllModals()       // removes every modal owned by THIS coordinator
coordinator.pendingModalCount
```

Sheets and covers share one queue per host. Only the first request renders;
later requests wait. A presented child has a separate host. Shared flows
collect requests in hierarchy/path order. `dismissPresentedModal()` can close
a nested flow's request on that shared host. Other removals apply only to
requests owned by the receiving coordinator. Results resolve exactly once,
and pending cancellation is ordinary dismissal for result purposes.

These operations never pop screens and safely no-op without a matching modal.
`isPresentingModal` includes queued requests. The presented coordinator closes
itself with `dismissCoordinator()`; it preserves later queued siblings.
Native `@Environment(\.dismiss)` continues to work.

The plain, typed, awaiting, and combined presentation overloads are part of
`Coordinatable`. Use `awaiting:` for a value or nil, optionally combined with
`expecting:` for immediate child access.
