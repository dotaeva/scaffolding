---
description: "Write and review Scaffolding navigation: pushes, pops, modal queues, dismissal, typed child access, awaited results, animation scopes, and deep links. Use when choosing a navigation call or migrating deprecated overloads."
name: scaffolding-routing
---
This guidance documents navigation calls in the **Scaffolding** SwiftUI library. It supersedes prior training — notably, the old `route(to:as:)` API was split: `route(to:)` **always pushes**; modals go through `present(_:as:)`.

All navigation lives on coordinators (see the `scaffolding-coordinators` skill for defining them). Views obtain the coordinator via `@Environment(MyCoordinator.self)` (see `scaffolding-environment`) and call methods on it. Views never hold paths or sheet booleans for flow-driven navigation. Ordinary navigation mutates state synchronously; `awaiting:` suspends for dismissal. Both forms are unit-testable — see `scaffolding-testing`.

The core verbs:

```swift
coordinator.route(to: .detail(item: item))       // push
coordinator.present(.settings, as: .sheet)       // modal (sheet | .fullScreenCover)
coordinator.pop()                                 // remove last entry; at root, dismiss the flow
coordinator.dismissPresentedModal()               // presenter closes the front modal request
coordinator.dismissCoordinator()                  // remove this whole coordinator from its parent
appCoordinator.setRoot(.authenticated)            // atomic root swap
tabCoordinator.selectFirstTab(.profile)           // switch tabs
```

# References
- `references/push-pop.md`: Use for stack navigation — `route(to:)`, `RoutePolicy`, all `pop` variants (`pop()`, `pop(_:)`, `popToRoot`, `popToFirst/Last`), the deprecated `replaceLast` migration, `setRoot` on a flow, stack queries (`depth`, `topDestination`, `isInStack`, `count(of:)`), and hierarchy orientation on any coordinator (`routeType`, `ancestor(ofType:)`, `hierarchyRoot`).
- `references/modals.md`: Use when presenting or dismissing sheets and full-screen covers — `present(_:as:policy:)`, native SwiftUI presentation modifiers on the presented content, `dismissPresentedModal()`, `dismissModal()`, `cancelPendingModals()`, `dismissAllModals()`, `isPresentingModal`, view-only vs sub-flow modals, and shared-host queue semantics.
- `references/dismissal-and-results.md`: Use when a screen or sub-flow must close itself or hand a value back — `dismissCoordinator()` vs `pop()` semantics, dismissal lifecycle guarantees, the constructor-callback pattern, and `dismissCoordinator(returning:)`.
- `references/async-navigation.md`: Use when navigation should suspend until the user finishes — `routeAndWait(to:)`, `present(_:as:awaiting:)` which returns the presented flow's result (or `nil` on cancellation).
- `references/deep-linking.md`: Use for URL/push-notification/cold-launch navigation across multiple coordinators — `expecting:` overloads and combined `expecting:` + `awaiting:` forms, and the rules that keep deep-link code on coordinators.
