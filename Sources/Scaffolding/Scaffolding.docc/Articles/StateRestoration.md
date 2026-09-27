# Restoring Navigation State

Capture the coordinator tree as `Data` and restore it when a scene starts.

## Overview

Navigation state lives on coordinators, so you can serialize it without
touching a view. Make routes `Codable`, capture at a checkpoint, and restore
once per scene. Keep these snapshots separate from your app's data.

```swift
@MainActor @Observable @Scaffoldable(codable: true)
final class HomeCoordinator: @MainActor FlowCoordinatable {
    var stack = FlowStack<HomeCoordinator>(root: .home)

    func home() -> some View { HomeView() }
    func detail(id: Item.ID) -> some View { DetailView(id: id) }
}
```

Add `codable: true` to every coordinator that should persist. Every route
parameter must then be `Codable`. Pass identifiers, not models or closures.

## Capture

```swift
let data = try appCoordinator.captureNavigationState(version: 1)
UserDefaults.standard.set(data, forKey: "navigation")
```

Capture walks the resolved tree from the receiver. It throws
``NavigationStateError/unsupported(coordinator:)`` if the receiver is not
`codable: true`, and throws on encoding failures. Non-codable children
restore at their initial state.

| Captured | Not captured |
|---|---|
| Route payloads and child navigation | Domain data, view `@State`, form input |
| Pushed paths, modals, sheet/cover style | Running tasks, awaiting callers, closures |
| Tabs and selection | Badges and accessibility identifiers |
| Columns, visibility, compact column | Sheet detents and dismissal settings |

## Restore

```swift
if let data = UserDefaults.standard.data(forKey: "navigation") {
    try appCoordinator.restoreNavigationState(from: data, mode: .replace)
}
```

| Mode | Behavior |
|---|---|
| ``NavigationRestorationMode/replace`` | Clears existing pushes and modals first. Use it for seeded stacks and repeated restores. |
| ``NavigationRestorationMode/replay`` | Replays the snapshot on top of the current state; a flow whose saved root differs is cleared by the root change. The default of ``Coordinatable/restoreNavigationState(from:)``. |

In `.replace` mode, an unchanged root, tab, or column whose child has no saved
state is rebuilt through its route factory. This resets unsupported children to
their initial state and resolves pending results on the removed branch. Unaffected
tabs keep their identity. In `.replay` mode, an unchanged child with no saved
state keeps its existing navigation.

Unknown or undecodable routes are skipped with their children, so removing a
route in an update degrades gracefully. Reapply badges, identifiers, and sheet
settings after restoring.

## Diagnose partial results

```swift
let capture = try appCoordinator.captureNavigationStateWithReport(version: 2)
persist(capture.data)
for issue in capture.report.issues {
    print(issue.coordinator, issue.path, issue.reason, issue.message)
}

let report = try appCoordinator.restoreNavigationStateWithReport(from: data)
print(report.restoredRoutes, report.skippedRoutes)
```

Report capture records encoding failures as issues instead of throwing; an
unsupported receiver still throws. Issues name encoding and decoding failures,
unavailable routes, unsupported coordinators, and invalid tab sets, with paths
such as `tabs[1]`. `restoreNavigationStateWithReport` defaults to `.replace`.

## Migrate old snapshots

`version:` is **your** snapshot version; advance it when route payloads
change. The library records its own schema separately. Snapshots without a
version read as version 0. The migration hook runs before decoding and
before any navigation changes:

```swift
let report = try appCoordinator.restoreNavigationStateWithReport(from: data) { bytes, oldVersion in
    try migrateNavigationSnapshot(bytes, from: oldVersion)  // your function
}
```

Return migrated bytes, or throw to leave the hierarchy untouched. An unknown
future library schema also throws before mutation. Test migrations against
saved fixtures.

## API

| Intent | Method |
|---|---|
| Capture strictly | ``Coordinatable/captureNavigationState(version:)`` |
| Capture with a report | ``Coordinatable/captureNavigationStateWithReport(version:)`` |
| Restore | ``Coordinatable/restoreNavigationState(from:mode:)`` |
| Restore with a report and migration | ``Coordinatable/restoreNavigationStateWithReport(from:mode:migrate:)`` |

## Rules

- Restore once per scene, before the user navigates.
- A restored modal comes back without its original awaiting caller.
- To start deeper without a snapshot, seed `FlowStack(root:pushing:)`
  instead; see <doc:Flows#Start-deeper-than-the-root>.

## See Also

- <doc:DefiningRoutes>
- <doc:TestingCoordinators>
