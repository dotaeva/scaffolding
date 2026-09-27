# Testing Coordinators

Unit-test navigation against the coordinator itself — no host app, no
rendered view.

## Overview

A coordinator is a plain `@MainActor @Observable` class, and navigation
changes its state synchronously. Test the shipping coordinator and assert on
its public queries. Link **ScaffoldingTesting** only into test targets; it
imports Swift Testing.

```swift
// Package.swift
.testTarget(name: "MyAppTests", dependencies: [
    "MyApp",
    .product(name: "ScaffoldingTesting", package: "scaffolding"),
])
```

```swift
import Testing
import Scaffolding
import ScaffoldingTesting
@testable import MyApp

@MainActor
@Suite("Home flow")
struct HomeFlowTests {
    @Test func openingAnItemPushesOneScreen() {
        let home = HomeCoordinator().activated()

        home.open(Item.samples[0])

        #expect(home.depth == 1)
        #expect(home.topDestination == .detail)
    }
}
```

## Use the helpers

| Helper | Use |
|---|---|
| `activated()` | Resolve the declared initial hierarchy. Call it first when a test depends on initial roots or tabs. |
| `descendant(ofType:)`, `descendants(ofType:)` | Find a child the code under test already created. Never creates one. |
| `hierarchyContains(_:_:as:)` | Assert that a coordinator type shows a case in a role, anywhere in the tree. |
| `waitUntil(_:timeout:)` | Wait for a condition against a deadline (default 5 s). Returns `Bool`. |

## Assert the tree

Assert single coordinators with their queries — `depth`, `topDestination`,
`isInStack(_:)`, `isRoot(_:)`, `selectedTabDestination`, `badge(for:)`,
`detailDestination`, `isPresentingModal`. For multi-step navigation such as a
deep link, assert the tree:

```swift
app.handle(URL(string: "myapp://holding/NVDA")!)

#expect(app.hierarchyContains(InvestCoordinator.self, .holding, as: .push))
#expect(app.hierarchyContains(MainTabCoordinator.self, .invest,
                              as: .tab(index: 2, isSelected: true)))
```

Split columns use the `.column` role:

```swift
let split = LibraryCoordinator().activated()
split.select(.mars)

#expect(split.isDetail(.planet))
#expect(split.hierarchyContains(LibraryCoordinator.self, .planet, as: .column(.detail)))
```

## Test modals and tab guards

```swift
cards.openDetail(card)
cards.openDetail(card)                       // .distinct ignores the double tap
#expect(cards.count(of: .cardDetail) == 1)

cards.dismissPresentedModal()
#expect(!cards.isPresentingModal)

// Call shouldSelect the way the tab bar does.
#expect(!tabs.shouldSelect(tab: .invest, isReselection: false))
#expect(tabs.isPresentingModal)
```

`selectFirstTab` bypasses `shouldSelect`, so it tests selection, not the guard.

## Test awaited navigation

Start the awaiting call in a `Task`, wait for the modal, then resolve it.
Guard `waitUntil` before awaiting work that could never finish:

```swift
let picking = Task { await cards.changeLimit() }   // awaits present(.limitPicker, …)
guard await waitUntil({ cards.isPresentingModal }, timeout: .seconds(2)) else {
    picking.cancel()
    return
}

let picker = try #require(cards.descendant(ofType: LimitCoordinator.self))
picker.finish(2_000)                               // dismissCoordinator(returning:)
await picking.value
#expect(cards.limit == 2_000)
```

A presenter-side dismissal stands in for a swipe and returns `nil`:

```swift
let waiting = Task { await cards.present(.limitPicker, awaiting: Decimal.self) }
guard await waitUntil({ cards.isPresentingModal }, timeout: .seconds(2)) else {
    waiting.cancel()
    return
}
cards.dismissPresentedModal()
#expect(await waiting.value == nil)
```

## Test restoration

Check the report, the restored structure, and the inputs that identify the
restored record. Here the root route `.profile(userID:)` builds a
`ProfileCoordinator` with a readable `userID`; both coordinators use
`@Scaffoldable(codable: true)`.

<!-- checked-swift: restoration-test -->
```swift
@MainActor @Test func restoresProfile() throws {
    let original = AppCoordinator().activated()
    original.setRoot(.profile(userID: 7))
    let data = try original.captureNavigationState()

    let restored = AppCoordinator().activated()
    let report = try restored.restoreNavigationStateWithReport(from: data, mode: .replace)
    #expect(report.issues.isEmpty)
    #expect(restored.isRoot(.profile))
    let profile = try #require(restored.descendant(ofType: ProfileCoordinator.self))
    #expect(profile.userID == 7)
}
```

`debugHierarchy()` and case-based hierarchy queries omit route payloads.
Matching them alone cannot distinguish user 7 from user 99. For routes that
build views, verify the restored input through an app-owned model or a rendered
test; coordinator-only tests cannot inspect view state.

## Rules

- A `waitUntil` timeout records a test issue; cancellation returns `false`
  silently.
- Test task cancellation separately from dismissal: cancelling leaves the UI
  in place.
- Don't test `\.destination` or view `@State` here — they exist only in
  rendered views. Use hosted or UI tests for rendering.
- Don't store child references on a coordinator to make it testable.

## See Also

- <doc:Orientation>
- <doc:DeepLinking>
- <doc:StateRestoration>
