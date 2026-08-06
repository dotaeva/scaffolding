---
description: "Unit-test navigation in apps using the Scaffolding SwiftUI library — coordinators are plain @Observable classes, so the whole navigation layer is testable without rendering a view. Consult when writing or reviewing tests for a FlowCoordinatable / TabCoordinatable / RootCoordinatable, when a navigation test asserts nothing or reads empty state, or when deciding what to assert about navigation. Covers: the ScaffoldingTesting library (activated(), descendant(ofType:), hierarchyContains, waitUntil), why a coordinator must be activated before root-dependent assertions, the public introspection surface to assert on (depth, topDestination, isInStack, count(of:), isPresentingModal, isRoot, badge(for:), routeType, hierarchySnapshot), obtaining typed child-coordinator handles, testing modals and presenter-side dismissal, awaitable navigation (routeAndWait / presentAndWait / present(_:awaiting:)), result delivery, tab guards via shouldSelect, deep links, state restoration, and what not to test."
name: scaffolding-testing
---
Navigation in **Scaffolding** is testable because a coordinator is a plain `@MainActor @Observable` class: routes are functions, state lives in `FlowStack` / `Root` / `TabItems`, and every navigation call mutates that state **synchronously**. Nothing needs a view, a host app, or a rendered `NavigationStack`. Test the shipping coordinator directly — no test double, no `ViewInspector`.

If navigation logic can't be reached from a test, that's a design smell, not a framework limit: state has leaked into a view (see `scaffolding-coordinators`).

## The ScaffoldingTesting library

The package exposes a second product, `ScaffoldingTesting`. Link it into the **test target only** — it imports Swift Testing.

```swift
// Package.swift
.testTarget(name: "MyAppTests", dependencies: [
    "MyApp",
    .product(name: "ScaffoldingTesting", package: "scaffolding"),
])
```

| API | Purpose |
|---|---|
| `coordinator.activated()` | Resolves the initial root / tabs and returns the coordinator. Required before root-dependent assertions. |
| `coordinator.descendant(ofType:)` · `descendants(ofType:)` | Typed handle(s) on already-created children, including ones the code under test presented itself. Never materialises anything. |
| `coordinator.hierarchyContains(_:_:)` · `(_:_:as:)` | Typed whole-tree assertion; replaces matching `debugHierarchy()` strings. |
| `await waitUntil { … }` | Spins the main actor until a condition holds, for the awaitable navigation API. Records an issue on timeout instead of hanging. |

## Test-suite shape

```swift
import Testing
import Scaffolding
import ScaffoldingTesting
@testable import MyApp

@MainActor                     // coordinators are MainActor-isolated
@Suite("Home flow")
struct HomeFlowTests {
    @Test("opening a transaction pushes one screen")
    func openPushes() {
        let home = HomeCoordinator().activated()

        home.open(Transaction.sample)

        #expect(home.depth == 1)
        #expect(home.topDestination == .transaction)
    }
}
```

### Always activate first

`FlowStack` / `Root` / `TabItems` resolve their initial destinations **lazily**, the first time the framework touches `view`, `anyStack`, `anyRoot`, or `anyTabItems` — normally at first render. A test renders nothing, so without `activated()` the root is unresolved and root-dependent reads (`topDestination`, `isRoot(_:)`, `hierarchyContains`, `debugHierarchy()`) come back empty. Pushes and presentations work without it; assertions about the root don't. Calling it twice is harmless.

## What to assert on

All public, all cheap, all synchronous:

| Question | API |
|---|---|
| How many screens are pushed? | `flow.depth` (root excluded, modals excluded) |
| What's on top? | `flow.topDestination` — `Destinations.Meta` |
| Is a case in the stack? | `flow.isInStack(.detail)`, `flow.count(of: .detail)` |
| Is a modal up? | `coordinator.isPresentingModal` (every coordinator type) |
| Which root is showing? | `rootCoordinator.isRoot(.main)` |
| Which tab is selected? | `tab.tabItems.selectedTab`, or your own derived index |
| Is a tab present / badged? | `tab.isInTabItems(.promo)`, `tab.badge(for: .invest)` |
| How was this coordinator presented? | `coordinator.routeType` |
| Who's above it? | `coordinator.ancestor(ofType:)`, `coordinator.hierarchyRoot` |
| What does the whole tree look like? | `coordinator.hierarchyContains(_:_:as:)`, or `hierarchySnapshot()` |

Never assert on framework internals (`Destination`, `pushType`, `resolution`) or on SwiftUI output.

### Whole-tree assertions

For multi-step navigation (deep links, restoration), assert the shape of the tree rather than drilling down — and prefer the typed matcher over `debugHierarchy().contains("…")`:

```swift
app.handle(URL(string: "myapp://holding/NVDA")!)

#expect(app.hierarchyContains(InvestCoordinator.self, .holding, as: .push))
#expect(app.hierarchyContains(MainTabCoordinator.self, .invest, as: .tab(index: 2, isSelected: true)))
#expect(!app.hierarchyContains(HomeCoordinator.self, .transaction))
```

The first argument is the coordinator that owns the destination; it scopes the meta so the case can be written as a leading dot. Roles are `.root`, `.push`, `.sheet`, `.fullScreenCover`, `.tab(index:isSelected:)`; omit `as:` to match any role.

When yes/no isn't enough, `hierarchySnapshot()` (from the main library) returns `[HierarchyNode]` with `role`, `meta`, `coordinator`, `hasCoordinator`, and `children` — the structured form of what `debugHierarchy()` prints, and what the helpers above are built on.

## Getting a handle on a child coordinator

Two tools, for two different situations:

- **The test performs the navigation** → the `expecting:` overloads navigate *and* return the resolved child (`route`, `present`, `setRoot`, `selectFirstTab`/`selectLastTab`, `select(index:)`/`select(id:)`, `appendTab`, `insertTab`, `popToFirst`, `popToLast`):

  ```swift
  let picker = cards.present(.limitPicker, expecting: LimitCoordinator.self)
  picker?.openCustom()

  #expect(picker?.depth == 1)   // pushed inside the sheet
  #expect(cards.depth == 0)     // presenter's stack untouched
  ```

- **The code under test performs it** → `descendant(ofType:)`. This is the only way in when the action awaits its own presentation, since `present(_:awaiting:)` hands back no coordinator:

  ```swift
  let picking = Task { await cards.changeLimit() }
  await waitUntil { cards.isPresentingModal }

  cards.descendant(ofType: LimitCoordinator.self)?.finish(2_000)
  await picking.value

  #expect(cards.limit == 2_000)
  ```

Returning the child from an action is also a good seam — `@discardableResult` keeps call sites unchanged:

```swift
@discardableResult
func startOrder(for holding: Holding) -> OrderCoordinator? {
    present(.buy(holding: holding, onComplete: { … }), as: .sheet, expecting: OrderCoordinator.self)
}
```

Never store child coordinator references on a coordinator to make it testable — that breaks the ownership model the library relies on.

## Modals

```swift
cards.openDetail(card)
#expect(cards.isPresentingModal)
#expect(cards.depth == 0)                  // a modal is not a push
#expect(cards.count(of: .cardDetail) == 1) // .distinct swallowed the double tap

cards.resolveFreeze(card, freeze: true)    // presenter-side dismissModal()
#expect(!cards.isPresentingModal)
```

- `dismissModal()` is a safe no-op with nothing presented, and never touches pushes — worth pinning down when a screen has both.
- `onDismiss` fires exactly once however the destination leaves; the awaited equivalent (`routeAndWait`) resumes exactly once for the same reasons.
- The presented coordinator's own exit is `dismissCoordinator()` / `dismissCoordinator(returning:)`; assert it from the presenter's `isPresentingModal`.

## Awaitable navigation

Drive the suspending call from a `Task` and resolve it from the test body:

```swift
let waiting = Task { await home.routeAndWait(to: .categoryPicker) }
await waitUntil { home.topDestination == .categoryPicker }

home.category = "Groceries"      // what the picker writes
home.pop()
await waiting.value

#expect(home.depth == 0)
```

Cancellation deserves its own test — any dismissal that isn't `dismissCoordinator(returning:)` resumes with `nil`:

```swift
let picking = Task { await cards.present(.limitPicker, awaiting: Decimal.self) }
await waitUntil { cards.isPresentingModal }
cards.dismissModal()             // stands in for a swipe-down

#expect(await picking.value == nil)
```

## Tabs

`shouldSelect(tab:isReselection:)` is an ordinary method — call it the way the tab bar does, and assert both the veto and its side effect:

```swift
#expect(!tabs.shouldSelect(tab: .invest, isReselection: false))
#expect(tabs.isPresentingModal)          // the gate it presented instead
#expect(tabs.selectedIndex == 0)         // selection never moved

// Re-tap pops the selected flow to its root.
let home = tabs.selectFirstTab(.home, expecting: HomeCoordinator.self)
home?.open(Transaction.samples[0])
_ = tabs.shouldSelect(tab: .home, isReselection: true)
#expect(home?.depth == 0)
```

Programmatic selection (`selectFirstTab`, `select(index:)`) bypasses the hook, so a test that calls those is testing selection, not the guard. Custom tab bars that consult the hook themselves should be tested through their own tap entry point.

## Roots, ancestors, and deep links

```swift
let login = app.setRoot(.login, expecting: LoginCoordinator.self)
#expect(login?.ancestor(ofType: AppCoordinator.self) === app)

login?.submit()             // reaches up via ancestor(ofType:)
#expect(app.isRoot(.main))
```

A root swap resolves a **fresh** child — assert that old state is gone (`second !== first`, `second?.depth == 0`) rather than assuming it persists. Deep links are one coordinator call, so test them as one, and cover the guards: a link arriving while unauthenticated should leave the tree alone.

## State restoration

```swift
let snapshot = try app.captureNavigationState()
app.signOut()

app.setRoot(.main, animation: nil)      // restoration replays onto a fresh tree
try app.restoreNavigationState(from: snapshot)

#expect(app.hierarchyContains(HomeCoordinator.self, .transaction, as: .push))
```

Also pin the degradation: a subtree that opts out of `codable:` restores at its initial position while the rest of the tree comes back — assert the absence, not a crash.

## Don't test

- **SwiftUI rendering.** Route functions return views; that a `NavigationStack` displays the top destination is the framework's job.
- **`\.destination` in unit tests.** It's populated when the framework materialises a destination for a view, not by constructing one in a test (same caveat as previews — see `scaffolding-environment`).
- **Framework internals.** `Destination`, `resolution`, `pushType`: not your contract.
- **Views holding navigation state.** If a test needs to poke a view's `@State` to drive navigation, fix the design instead: move the transition to the coordinator.
