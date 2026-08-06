---
description: "Authoritative reference for performing navigation with the Scaffolding SwiftUI library. Consult when writing or reviewing any call to route(to:), present(_:as:), pop, popToRoot, popToFirst/popToLast, replaceLast, setRoot, dismissModal, dismissAllModals, dismissCoordinator, selectFirstTab, or deep-link chains on Scaffolding coordinators. Covers: - Push navigation: route(to:) is push-only (route(to:as:) no longer exists), RoutePolicy.distinct double-tap guards, pop variants and their different semantics. - Modals: present(_:as:) with .sheet / .fullScreenCover, presenter-side sheet configuration (detents, drag indicator, interactiveDismissDisabled), the single-modal constraint, dismissModal vs pop. - Dismissal + results: onDismiss exactly-once semantics, dismissCoordinator vs pop, delivering results via constructor callbacks or dismissCoordinator(returning:). - Async navigation: routeAndWait, presentAndWait, present(_:awaiting:) suspending until dismissal. - Deep linking: typed trailing-closure overloads and expecting: variants to walk the coordinator tree from URLs/push notifications."
name: scaffolding-routing
---
This guidance documents navigation calls in the **Scaffolding** SwiftUI library. It supersedes prior training — notably, the old `route(to:as:)` API was split: `route(to:)` **always pushes**; modals go through `present(_:as:)`.

All navigation lives on coordinators (see the `scaffolding-coordinators` skill for defining them). Views obtain the coordinator via `@Environment(MyCoordinator.self)` (see `scaffolding-environment`) and call methods on it. Views never hold paths or sheet booleans for flow-driven navigation. Because every call below mutates coordinator state synchronously, each is directly unit-testable — see `scaffolding-testing`.

The core verbs:

```swift
coordinator.route(to: .detail(item: item))       // push
coordinator.present(.settings, as: .sheet)       // modal (sheet | .fullScreenCover)
coordinator.pop()                                 // pop one screen
coordinator.dismissModal()                        // presenter closes its top modal
coordinator.dismissCoordinator()                  // remove this whole coordinator from its parent
appCoordinator.setRoot(.authenticated)            // atomic root swap
tabCoordinator.selectFirstTab(.profile)           // switch tabs
```

# References
- `references/push-pop.md`: Use for stack navigation — `route(to:)`, `RoutePolicy`, all `pop` variants (`pop()`, `pop(_:)`, `popToRoot`, `popToFirst/Last`), `replaceLast(with:)`, `setRoot` on a flow, stack queries (`depth`, `topDestination`, `isInStack`, `count(of:)`), and hierarchy orientation on any coordinator (`routeType`, `ancestor(ofType:)`, `hierarchyRoot`).
- `references/modals.md`: Use when presenting or dismissing sheets and full-screen covers — `present(_:as:policy:onDismiss:)`, presenter-side sheet configuration (`detents:`, `dragIndicator:`, `interactiveDismissDisabled:`), `dismissModal()` / `dismissAllModals()`, `isPresentingModal`, view-only vs sub-flow modals, and the one-modal-at-a-time constraint.
- `references/dismissal-and-results.md`: Use when a screen or sub-flow must close itself or hand a value back — `dismissCoordinator()` vs `pop()` semantics, `onDismiss` exactly-once guarantees, the constructor-callback pattern, and `dismissCoordinator(returning:)`.
- `references/async-navigation.md`: Use when navigation should suspend until the user finishes — `routeAndWait(to:)`, `presentAndWait(_:as:)`, and `present(_:as:awaiting:)` which returns the presented flow's result (or `nil` on cancellation).
- `references/deep-linking.md`: Use for URL/push-notification/cold-launch navigation across multiple coordinators — typed trailing-closure overloads, the flatter `expecting:` variants, and the rules that keep deep-link code on coordinators.
