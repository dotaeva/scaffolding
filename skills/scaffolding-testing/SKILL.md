---
description: "Test Scaffolding navigation with Swift Testing and ScaffoldingTesting. Use for activation, typed hierarchy assertions, deadline-based waits, results and cancellation, tabs, split columns, deep links, or restoration."
name: scaffolding-testing
---

# Test navigation through the coordinator

Link **ScaffoldingTesting** only into the test target; it imports Swift Testing.
Test the shipping coordinator on `@MainActor`. Ordinary navigation changes state
synchronously; awaited navigation needs a task that the test can complete.

```swift
// Package.swift
.testTarget(name: "MyAppTests", dependencies: [
    "MyApp",
    .product(name: "ScaffoldingTesting", package: "scaffolding"),
])
```

## Establish initial state

```swift
import Testing
import Scaffolding
import ScaffoldingTesting
@testable import MyApp

@MainActor @Suite("Home flow")
struct HomeFlowTests {
    @Test func opensDetail() {
        let home = HomeCoordinator().activated()
        home.open(Transaction.sample)
        #expect(home.depth == 1)
        #expect(home.topDestination == .transaction)
    }
}
```

Containers resolve lazily. Navigation and many queries resolve them;
`debugHierarchy()` and `hierarchySnapshot()` deliberately do not. Use
`activated()` when a test needs the complete initial hierarchy. Calling it
again is harmless.

## Assert public behavior

| Question | API |
|---|---|
| Number and top case of pushes | `depth`, `topDestination` (exclude modals) |
| Own entries matching a case | `isInStack(_:)`, `count(of:)` (include modals, exclude root) |
| Modal requests, including pending | `isPresentingModal`, `pendingModalCount` |
| Selected root / tab | `isRoot(_:)`, `selectedTabDestination`, `selectedTabIndex` |
| Tab metadata | `badge(for:)`, `tabAccessibilityIdentifier(for:)` |
| Split columns | `sidebarDestination`, `contentDestination`, `detailDestination`, `isDetail(_:)` |
| Presentation and ancestry | `routeType`, `ancestor(ofType:)`, `hierarchyRoot` |
| Whole-tree shape | `hierarchyContains(_:_:as:)`, `hierarchySnapshot()` |

Prefer typed assertions over matching debug strings:

```swift
#expect(app.hierarchyContains(HomeCoordinator.self, .transaction, as: .push))
#expect(app.hierarchyContains(MainTabCoordinator.self, .home,
                              as: .tab(index: 0, isSelected: true)))
#expect(split.hierarchyContains(LibraryCoordinator.self, .planet,
                                as: .column(.detail)))
```

Use `expecting:` when the test performs navigation. Use `descendant(ofType:)`
or `descendants(ofType:)` to find children that the code under test created.
Those helpers never materialize children. Do not add stored child references
to production coordinators just to make tests easier.

## Await a result safely

```swift
let picking = Task { await cards.present(.limitPicker, awaiting: Decimal.self) }
defer { picking.cancel() }
guard await waitUntil({ cards.isPresentingModal }, timeout: .seconds(2)) else {
    picking.cancel()
    return
}

let picker = try #require(cards.descendant(ofType: LimitCoordinator.self))
picker.finish(2_000)
#expect(await picking.value == 2_000)
```

The enclosing test must be `async throws`. `waitUntil` returns `Bool`, uses a
monotonic deadline (five seconds by default), and records an issue at the caller
on timeout. Cancellation returns false without a timeout issue. Guard the result
before awaiting a task that cannot complete after a failed condition. The old
`iterations:` overload is deprecated.

For cancellation, cancel the waiting task and assert that the route remains.
For dismissal without a result, call `dismissPresentedModal()` and assert nil.
Assert the navigation state as well as the nil return to distinguish these behaviors.

## Modal queues and tab guards

With A visible and B queued on the same coordinator, `dismissModal()` removes B;
`dismissPresentedModal()` closes A; `cancelPendingModals()` removes B and leaves
A. Verify the operation your action intends to perform. Modal helpers never pop
pushed destinations. Child self-dismissal uses `dismissCoordinator()`.

`shouldSelect(tab:isReselection:)` is an ordinary method. Call it explicitly to
test a veto or re-tap side effect. `selectFirstTab` is programmatic selection
and bypasses that hook. Check `selectedTabIndex`, not a nonexistent `selectedIndex`.

## Deep links and restoration

Test a deep link as one coordinator action, including unauthenticated and
repeated-link cases. `setRoot` creates a fresh child even if its case is unchanged;
assert whether the action should retain or replace an existing branch.

```swift
let data = try original.captureNavigationState(version: 1)
let restored = AppCoordinator().activated()
let report = try restored.restoreNavigationStateWithReport(from: data, mode: .replace)
#expect(report.issues.isEmpty)
#expect(restored.hierarchyContains(HomeCoordinator.self, .transaction, as: .push))
```

Test expected partial recovery with saved fixtures when routes change. An
unsupported child restores at its initial state; an unsupported capture root
throws. Repeated `.replace` restoration should not duplicate seeded paths.

## Keep unit and rendered checks separate

Coordinator tests assert decisions and tree state. They do not inspect a view's
`@State` or environment `\.destination`. A bare view preview also lacks real
destination metadata; a coordinator preview does not.

Library changes affecting rendering need hosted checks as well. `swift test`
includes macOS hosted regressions; check iOS presentation and native tab
metadata in a running app. Platform compilation alone cannot verify them.
