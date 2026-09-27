# Structuring a Modular App

Split features into packages that expose coordinators, and connect them
through results and injected contracts instead of ancestor lookups.

## Overview

In a modular app each feature is a Swift package with a public coordinator
and internal screens. Dependencies point one way: the composition root
imports features; features import shared modules and the child features they
compose.

That means a feature cannot name the coordinator hosting it — and should not
try. The same feature may be pushed in a tab, placed in a split column, or
presented by another feature. ``Coordinatable/ancestor(ofType:)`` and
`@Environment(AppCoordinator.self)` both need that concrete type, so they have
no place in feature code. A feature talks upward through three channels:

| Channel | Use it for |
|---|---|
| A result | Returning a value to whoever presented or pushed it |
| An injected capability | App-level actions such as sign-out or opening a record elsewhere |
| A selection delegate | Asking the host to show something, without knowing the layout |

The [Atlas example](https://github.com/dotaeva/scaffolding/tree/main/Example/Atlas)
builds a travel app from ten packages this way.

## Draw the module graph

```
App target
└─ AppFeature        composition root: root coordinator, deep links
   ├─ Welcome
   └─ Shell          tabs on iPhone, split view on iPad and Mac
      ├─ Explore ──► Places ──► Planner
      └─ Saved ────► Places, Planner

Every feature ──► Domain   models and capability protocols
```

- Features never import AppFeature or Shell.
- Put the protocols features share in a module every feature can import. It
  does not need to import Scaffolding.

## Expose a coordinator, keep screens internal

```swift
// Planner package
@MainActor @Observable @Scaffoldable
public final class PlannerCoordinator: @MainActor FlowCoordinatable {
    public var stack = FlowStack<PlannerCoordinator>(root: .details)
    public let place: Place

    public init(place: Place) { self.place = place }

    func details() -> some View { PlanDetailsScreen() }
    func review() -> some View { PlanReviewScreen() }
}

extension PlannerCoordinator {
    public func finish(days: Int) {
        dismissCoordinator(returning: TripPlan(placeID: place.id, days: days))
    }
}
```

- Make the coordinator, its initializer, its container property, and its
  intent methods `public`. Protocol witnesses such as `stack` and
  `customize(_:)` must be `public` on a public coordinator.
- Keep route functions and screens internal. The generated `Destinations`
  follows the coordinator's access, so hosts can still pass its cases.
- Give hosts intents (`finish(days:)`, `showHighlights()`) rather than
  expecting them to assemble your routes.

## Return results upward

The host awaits the child. The child never learns who presented it:

```swift
// Places package
func plan() async {
    guard let plan = await present(.planner, awaiting: TripPlan.self) else { return }
    store.add(plan)
}
```

Cancelling returns `nil`. See <doc:ModalsAndResults#Await-a-result>.

## Inject capabilities for app-level actions

Declare a protocol in the shared module, conform the composition root to it,
and pass it down through initializers:

```swift
// Domain package
@MainActor
public protocol SessionActions: AnyObject {
    func signOut()
}

// Settings package
@MainActor @Observable @Scaffoldable
public final class SettingsCoordinator: @MainActor FlowCoordinatable {
    public var stack = FlowStack<SettingsCoordinator>(root: .settings)
    private weak var session: (any SessionActions)?

    public init(session: any SessionActions) { self.session = session }

    func settings() -> some View { SettingsScreen() }
}

extension SettingsCoordinator {
    public func signOut() { session?.signOut() }
}

// AppFeature package
extension AppCoordinator: SessionActions {
    public func signOut() {
        dismissAllModals()
        setRoot(.login)
    }
}
```

The root creates the child with `SettingsCoordinator(session: self)`, and
`SettingsScreen` calls `coordinator.signOut()` on its own coordinator. Hold
capabilities `weak`: the root owns the child, so a strong reference back
would form a cycle.

## Let the host choose the placement

A list feature asks its host to show a selection. The host decides whether
that means a push or a new detail column:

```swift
// Domain package
@MainActor
public protocol SelectionDelegate: AnyObject {
    func openPlace(_ id: String)
}

// Explore package
public func choose(_ id: String) {
    if let selection {
        selection.openPlace(id)          // split host: setDetail(.place(id:))
    } else {
        route(to: .place(id: id))        // tab host: push locally
    }
}
```

## Link deep from the composition root

Only the composition root imports every feature, so cross-module deep links
live there and chain public types with `expecting:`:

```swift
// AppFeature package
func openPlace(_ id: String) {
    let tabs = setRoot(.workspace, expecting: TabShellCoordinator.self)
    let explore = tabs?.selectFirstTab(.discover, expecting: ExploreCoordinator.self)
    explore?.popToRoot()
    explore?.route(to: .place(id: id), expecting: PlaceCoordinator.self)?.showHighlights()
}
```

See <doc:DeepLinking>.

## Test each package alone

Test a feature coordinator with a stub capability on the main actor. The test
target imports `Testing`, `ScaffoldingTesting`, the feature, and its shared
contract module:

<!-- checked-swift: modular-coordinator-test -->
```swift
@MainActor final class SessionSpy: SessionActions {
    var didSignOut = false
    func signOut() { didSignOut = true }
}

@MainActor @Test func signOutReachesTheSession() {
    let spy = SessionSpy()
    let settings = SettingsCoordinator(session: spy).activated()
    settings.signOut()
    #expect(spy.didSignOut)
}
```

Test cross-module flows in a separate package that imports the public
products, without `@testable`.

## Rules

- Features never import the modules that host them.
- Don't call `ancestor(ofType:)` or read an ancestor from the environment in
  feature code. Use a result, a capability, or a delegate.
- A view reads only its own module's coordinators from the environment.
- Hold injected capabilities and delegates `weak`.
- Put cross-module deep links on the composition root only.

## See Also

- <doc:MonolithicApps>
- <doc:ModalsAndResults>
- <doc:DeepLinking>
