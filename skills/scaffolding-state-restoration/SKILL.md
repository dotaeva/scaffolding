---
description: "Capture, restore, migrate, and diagnose Scaffolding navigation snapshots. Use for Codable routes, replay versus replacement, partial-restoration reports, per-scene checkpoints, and hierarchy inspection."
name: scaffolding-state-restoration
---

# Persist navigation, separately from app data

Use `@Scaffoldable(codable: true)` on every participating coordinator. All route
parameters must be `Codable`; prefer stable IDs to model objects. Closure route
parameters cannot be persisted. `awaiting:` avoids closure payloads, but the
waiting task itself cannot survive process restart.

```swift
@MainActor @Observable @Scaffoldable(codable: true)
final class HomeCoordinator: @MainActor FlowCoordinatable {
    var stack = FlowStack<HomeCoordinator>(root: .home)
    func home() -> some View { HomeView() }
    func detail(id: Int) -> some View { DetailView(id: id) }
}
```

## Choose strict or best-effort capture

```swift
let data = try app.captureNavigationState(version: 1) // throws route-encoding failures

let capture = try app.captureNavigationStateWithReport(version: 1)
persist(capture.data)
for issue in capture.report.issues {
    print(issue.coordinator, issue.path, issue.reason, issue.message)
}
```

Calling either API on an unsupported root coordinator throws
`NavigationStateError.unsupported`. Unsupported children restore with their
initial internal state; report capture identifies the missing subtrees.
`version:` is the application's payload version, separate from the library schema.
The no-version capture overload uses application version zero.

## Choose replacement explicitly

```swift
let report = try app.restoreNavigationStateWithReport(from: data, mode: .replace)
print(report.restoredRoutes, report.skippedRoutes)
```

- `.replace` clears existing pushes and modal requests before restoration.
  Use it for repeated restoration or seeded stacks.
- The report API defaults to `.replace`.
- The older `restoreNavigationState(from:)` overload keeps `.replay`, applying
  captured pushes/modals on top of the current state. Do not assume it replaces.
- Unknown, unavailable, or undecodable routes are skipped with their child state.
  Reports distinguish these failures. Invalid tab sets are not installed partially.
- Structurally invalid data and unknown future library schemas throw.

Restore once when establishing a scene, not on every view appearance. Keep
snapshots per window when windows have independent coordinators. Persist domain
stores separately; restoring navigation must not roll back user data.

## Migration before mutation

```swift
let report = try app.restoreNavigationStateWithReport(from: data) { bytes, oldVersion in
    try migrateNavigationSnapshot(bytes, from: oldVersion)
}
```

The application implements `migrateNavigationSnapshot`. The hook runs before
full decoding or navigation mutation, returns bytes, and may throw to leave the
tree unchanged. Treat snapshots as opaque in ordinary code; isolate payload
migration here and test against saved fixtures. Legacy snapshots have application
version zero.

## Snapshot scope

Captured: route payloads, pushed paths, modal requests and style, tab set and
selection, split columns and visibility, preferred compact column, and
materialized child navigation.

Not captured: domain stores, local form/view state, callbacks, running tasks,
awaited continuations, badges, accessibility identifiers, detents, drag indicators,
or interactive-dismiss configuration. Reapply app-owned metadata and configuration.
Choose whether transient result flows belong in a checkpoint at all.

## Seed a deterministic path

A hand-written coordinator initializer may construct:

```swift
stack = FlowStack(root: .home, pushing: [.detail(id: itemID)])
```

The initial path materializes at setup. There is no synthesized `init(initialRoute:)`.
This is useful for previews, tests, and known start positions without persistence.

## Inspect the live tree

```swift
print(coordinator.hierarchyRoot.debugHierarchy())
```

`debugHierarchy()` and `hierarchySnapshot()` never run route factories. They
show resolved state only; an untouched container may appear empty. Rendering,
navigation, many queries, or `activated()` in tests resolve initial state.

Use typed `hierarchyContains(_:_:as:)` assertions from **ScaffoldingTesting**
in tests rather than matching debug strings. See the `scaffolding-testing` skill.
