# Scaffolding — agent guide

Scaffolding's purpose is **modular navigation across coordinator boundaries**.
Coordinators own navigation state; views request actions. Feature modules expose
coordinators and keep their screens internal. Preserve that separation when
writing, reviewing, or testing code.

This file is the generation guide. The [DocC catalog](Sources/Scaffolding/Scaffolding.docc)
explains the public API.
The examples below assume app-specific models and views unless stated otherwise.

## Find the relevant reference

| Task | Reference |
|---|---|
| Pick a coordinator and structure modules | [Coordinator skill](skills/scaffolding-coordinators/SKILL.md) |
| Diagnose generated routes | [Macro rules](skills/scaffolding-coordinators/references/macro.md) |
| Push, present, dismiss, await, or deep-link | [Routing skill](skills/scaffolding-routing/SKILL.md) |
| Read environment values or build previews | [Environment skill](skills/scaffolding-environment/SKILL.md) |
| Persist or inspect navigation | [Restoration skill](skills/scaffolding-state-restoration/SKILL.md) |
| Test coordinator behavior | [Testing skill](skills/scaffolding-testing/SKILL.md) |
| Study a modular app | [Atlas guide](Example/Atlas/README.md) |

## Do not nest navigation containers

Never add `NavigationStack`, `NavigationView`, or a hand-built
`NavigationSplitView` inside a view returned by a flow route or inside its
`customize(_:)` wrapper. Scaffolding creates the container at the appropriate
boundary.

A pushed child flow **shares the host stack**. A modal child flow has a separate
stack; flows in independent tabs or split columns also get their own stacks.
Each coordinator still owns its destinations. Return a child coordinator when
a feature needs separate navigation logic:

```swift
// Wrong: creates a nested stack inside the flow.
func detail(item: Item) -> some View {
    NavigationStack { DetailView(item: item) }
}

// Correct: the framework composes the child at the coordinator boundary.
func detail(item: Item) -> any Coordinatable {
    DetailCoordinator(item: item)
}
```

A `SplitCoordinatable` may be a root destination, a tab, or a modal. It must not
be pushed or used as a flow's root: that would nest a split view inside a stack.

## Pick the owner and transition

| Intent | Use |
|---|---|
| Push a screen | `flow.route(to: .detail(id:))` |
| Go back within a flow | `flow.pop()` |
| Clear everything above the flow root | `flow.popToRoot()` |
| Present a coordinator-owned screen or multi-step flow | `coordinator.present(.settings, as: .sheet)` |
| Present a full-screen flow | `coordinator.present(.onboarding, as: .fullScreenCover)` |
| Close the front modal request from its presenter | `coordinator.dismissPresentedModal()` |
| Finish the whole child flow from inside | `child.dismissCoordinator()` |
| Replace the active app branch | `app.setRoot(.authenticated)` |
| Switch tabs | `tabs.selectFirstTab(.home)` |
| Replace split detail | `split.setDetail(.planet(id:))` |
| Show a local confirmation | Native `.alert`, `.confirmationDialog`, or `.sheet(item:)` |

Use a native sheet for local view-only UI. A single screen may still be a
coordinator route when its lifecycle, programmatic opening, or result belongs
to the flow. Views must not own paths or sheet booleans for coordinator-driven
navigation. Local form fields, selection highlights, and view-only presentation
state remain ordinary SwiftUI state.

Keep sheet appearance in SwiftUI: use plain `.sheet` and apply
`presentationDetents`, `presentationDragIndicator`, and
`interactiveDismissDisabled` to the presented view. For child flows, apply them
to the child's container in `customize(_:)` (in an extension). Pass ordinary
inputs if settings vary. The configured `.sheet(...)` factory,
`SheetConfiguration`, and `destination.modalConfiguration` are deprecated;
native modifiers do not populate that compatibility metadata.

`pop()` removes the last stored entry, which may be a modal. On an empty stack,
it attempts to dismiss the coordinator. `pop(_:)` stops at the root. Modal
helpers never pop screens.

## Declare routes in the class body

```swift
import SwiftUI
import Scaffolding

@MainActor @Observable @Scaffoldable
final class HomeCoordinator: @MainActor FlowCoordinatable {
    var stack = FlowStack<HomeCoordinator>(root: .home)

    func home() -> some View { HomeView() }
    func detail(id: Int) -> some View { DetailView(id: id) }
    func settings() -> any Coordinatable { SettingsCoordinator() }
}

extension HomeCoordinator {
    func openDetail(id: Int) {
        route(to: .detail(id: id))
    }

    func customize(_ view: AnyView) -> some View {
        view.tint(.indigo)
    }
}
```

The recommended shape is class body = container, stored state, and routes;
same-file extensions = actions, deep links, computed chrome, and `customize`.
A member macro cannot see extensions. A route declared there is untracked;
`customize` declared there needs no `@ScaffoldingIgnored`.

| Tracked return type | Meaning |
|---|---|
| `some View` | View destination |
| `any Coordinatable` | Child coordinator |
| `(any Coordinatable, some View)` | Tab child and label |
| `(some View, some View)` | Tab view and label |
| `(any Coordinatable, TabRole)` or `(some View, TabRole)` | Tab content and role |
| `(any Coordinatable, some View, TabRole)` | Tab child, label, and role |
| `(some View, some View, TabRole)` | Tab view, label, and role |

A concrete child return such as `-> LoginCoordinator` does **not** generate a
route. Use `any Coordinatable`. Properties, initializers, deinitializers,
`Void` actions, concrete return types, closures, arrays, and other tuple shapes
are skipped automatically.

Use `@ScaffoldingIgnored` only on a class-body function whose return type is
tracked but which is not a route: `customize(_:)`, a shared view builder, or an
unrouted coordinator factory. Do not annotate properties or `Void` helpers.
There is no opt-in tracking attribute.

Route factories must be synchronous, nonthrowing instance methods with unique
names and storable parameter types. Generic/opaque, variadic, and `inout`
parameters are diagnosed. Macro Boolean options require literal `true`/`false`.
Keep route factories declarative; put navigation side effects in actions.

The macro preserves `public` and `package` access, class-body `#if` branches,
and supported OS-introduction `@available` annotations. Unsupported availability
forms receive diagnostics. See the macro reference for exact constraints.

## Four coordinator protocols

| Protocol | Container | Owns |
|---|---|---|
| `FlowCoordinatable` | `FlowStack(root:pushing:)` | Root, pushes, modal requests |
| `RootCoordinatable` | `Root(root:)` | One active root branch and separate modal requests |
| `TabCoordinatable` | `TabItems(tabs:selectedIndex:visibility:)` | Tabs, selection, metadata, modal requests |
| `SplitCoordinatable` | `SplitColumns(sidebar:content:detail:)` | Columns, visibility, modal requests; `content:` is optional |

Container state is publicly readable and framework-writable. Existing callers
using `route`, `present`, and the other coordinator methods need no storage
migration. Use initializers to seed state; never replace a live container to
bypass dismissal lifetimes.

### Root swaps

`setRoot` creates a fresh destination even when its case is unchanged. The old
branch and its descendants are removed. On a root coordinator, modals owned
**directly by that coordinator** remain; call `dismissAllModals()` explicitly
when signing out should clear them. On a flow, `setRoot` also clears that flow's
pushed and modal destinations.

A top-level coordinator has no parent to dismiss it from. A root coordinator
hosted as a pushed or modal child can dismiss its enclosing branch.

### Tabs

Each independent tab usually returns a flow and a label:

```swift
func home() -> (any Coordinatable, some View) {
    (HomeCoordinator(), Label("Home", systemImage: "house"))
}
```

Read `selectedTabDestination` / `selectedTabIndex`, not a manually derived UUID
match. Selection methods retain existing tab state; `setTabs` creates a new set.
Metadata updates preserve tab content identity.

Set badges with `setBadge(_:for:)` and native tab identifiers with
`setTabAccessibilityIdentifier(_:for:)`. A plain accessibility identifier on
the label view does not reliably identify the native tab item.

`shouldSelect(tab:isReselection:)` intercepts **UI taps**. Returning false vetoes
a new selection; a re-tap has `isReselection == true` and ignores the return value.
Programmatic selection bypasses the hook, so redirection does not recurse.

For a custom bar, hide the native bar with `visibility: .hidden`, use unlabeled
routes returning `any Coordinatable` / `some View`, and render ordinary buttons
from the coordinator's state. Attach the bar in `customize(_:)`. If guarding
or re-taps matter, call `shouldSelect` yourself before programmatic selection.
Give icon-only buttons accessible labels; apply badge/identifier queries to
custom controls. See the [tab reference](skills/scaffolding-coordinators/references/tab.md).

### Split columns

`setDetail`, `setContent`, and `setSidebar` **replace** their column. A child loses
its previous pushed state. `setContent` can install the middle column at runtime;
`removeContent` removes it. Use `setColumnVisibility`, `toggleSidebar`, and
`setPreferredCompactColumn` for layout control.

Guard re-selection on domain identity:

```swift
func select(_ planet: Planet) {
    guard selectedPlanetID != planet.id else { return }
    selectedPlanetID = planet.id
    setDetail(.planet(id: planet.id))
}
```

`.distinct` compares only the case: `.planet(id: 1)` equals `.planet(id: 2)` for
this policy. It is unsuitable as a record-ID guard. Keep native `List(selection:)`
for highlighting, synced with the coordinator's domain state. A coordinator-driven
detail change does not automatically close an overlaid iPad sidebar; use
`setColumnVisibility(.detailOnly)` when that is the desired layout behavior.

Tab and column children are structural. They cannot dismiss themselves; remove
the tab or replace the column. Modals presented from them dismiss normally.

## Modal queues and results

Sheets and covers share one queue per presentation host. The front request
renders; later ones wait. A presented child has a separate host. Shared flow
queues follow hierarchy/path order, not a global presentation timestamp.
On macOS, full-screen covers render as sheets while keeping their recorded style.

With A visible and B queued on the same coordinator:

| Call | Result |
|---|---|
| `dismissPresentedModal()` | A closes; B advances |
| `dismissModal()` | B is removed; A remains |
| `cancelPendingModals()` | Pending B is removed; A remains |
| `dismissAllModals()` | All own requests are removed |

`dismissPresentedModal()` targets the shared host, including a nested flow's
front request. The other removal helpers target the receiver's own requests.
`isPresentingModal` includes pending requests; `pendingModalCount` counts own
requests behind the host's front request.

For a single result, prefer `awaiting:`:

```swift
let token = await present(.login, awaiting: AuthToken.self)
let item = await route(to: .picker, awaiting: Item.self)
```

A child returns with `dismissCoordinator(returning:)`. A view-only route reads
`@Environment(\.destination)` and calls `destination.dismiss(returning:)`.
Native `@Environment(\.dismiss)` keeps its usual behavior.

Combine labels when the child must be configured before waiting:

```swift
let (picker, result) = present(
    .picker, expecting: PickerCoordinator.self, awaiting: Item.self
)
picker?.route(to: .favorites)
let item = await result()
```

The combined call returns `(coordinator: T?, result: @MainActor () async -> Result?)`
synchronously. Only `result()` suspends. `present` supports all four protocols,
including generic `C: Coordinatable`; `route` supports flows.

- A view-only route or mismatched child type yields a nil handle; its result
  channel still works.
- A `.distinct` skip yields a nil handle and an immediately nil result; it
  does not wait on an existing destination.
- A result remains available after dismissal and can be read again.
- Cancelling a waiting task returns nil without removing UI or other waiters.
  A task cancelled before navigation creates no destination.
- Ordinary dismissal or a result-type mismatch returns nil. `Void.self` waits
  only; dismissal alone does not prove successful completion.

Removal detaches the branch before resolving descendants, deepest/topmost first.
Awaiting callers may navigate again safely. A retained destination dismissal
handle is inert after its route has gone. Constructor callbacks remain useful
for repeated updates before dismissal; closure payloads cannot be `Codable`.

`replaceLast`, navigation `onDismiss:` and typed trailing closures, and
`presentAndWait` are deprecated. Use ordinary `route` / `present` with `awaiting:`
for a value or nil. Do not generate new deprecated calls. For an explicit
pushed-screen replacement, guard `depth > 0`, pop, and route **only when no modal
is queued**. These are separate mutations, not an atomic replacement. Use
`setRoot` when the intent is a new flow root.

## Deep links and hierarchy orientation

Deep links live on a coordinator or the orchestrator owning the entry point.
Views should call one action, not assemble a multi-step chain. Use typed handles:

```swift
func openProfile(userID: Int) {
    let tabs = setRoot(.authenticated, expecting: MainTabCoordinator.self)
    let profile = tabs?.selectFirstTab(.profile, expecting: ProfileCoordinator.self)
    profile?.route(to: .userDetail(id: userID))
}
```

Choose deliberately whether a link resets or reuses an existing branch.
`expecting:` returns nil for a wrong child type; it does not undo the navigation.
Never cache child references for later deep links. From another coordinator,
reach upward with `ancestor(ofType:)`; from a view, read the nearest or ancestor
coordinator through `@Environment(Type.self)`.

```swift
print(coordinator.hierarchyRoot.debugHierarchy())
```

Print the tree before changing misbehaving routing. `debugHierarchy` and
`hierarchySnapshot` inspect resolved state without running factories. An
untouched container may appear empty; rendering, navigation, and many queries
resolve it. Use `activated()` in tests for the complete initial hierarchy.

| Question | Query |
|---|---|
| Push depth and top case | `depth`, `topDestination` (modals excluded) |
| Own entries containing a case | `isInStack`, `count(of:)` (root excluded; modals included) |
| Coordinator presentation | `coordinator.routeType` |
| Screen's role in its coordinator | `destination.routeType` |
| Screen's effective presentation | `destination.presentationType` |
| Split column | `destination.column` |

A root view inside a sheet keeps `routeType == .root` and inherits
`presentationType == .sheet`; a pushed view in that flow reads `.push`.
Use `presentationType` for adaptive Back/Close chrome.

## Environment and previews

Scaffolding injects the owning coordinator and ancestors into managed views.
`@Scaffoldable(injectsCoordinator: false)` hides only that coordinator, not its
ancestors. A non-optional typed environment lookup fails when the type is absent;
this is not a Swift concurrency issue. Use an optional lookup only if absence
is valid for that reusable view.

Coordinators do not read `@Environment`; inject dependencies through their
initializers. A bare view preview must receive each coordinator it reads:

```swift
#Preview("Home flow") { HomeCoordinator().view }
#Preview("Detail layout") {
    DetailView(id: 42).environment(HomeCoordinator())
}
```

The coordinator preview gets real destination metadata. The bare view gets
the default destination, not a pushed route. To preview a real deeper state,
write an initializer that seeds `FlowStack(root:pushing:)`. There is no
macro-synthesized `init(initialRoute:)`.

## Restoration and animation

Use `@Scaffoldable(codable: true)` with Codable route payloads. Strict capture
throws encoding failures; `captureNavigationStateWithReport(version:)` returns
best-effort data and diagnostics. An unsupported capture root throws; unsupported
children restore at their initial state.

`restoreNavigationStateWithReport(from:mode:migrate:)` defaults to `.replace`;
the original `restoreNavigationState(from:)` retains `.replay`. Choose replacement
for seeded or repeated restoration. The migration hook runs before mutation;
application versions are separate from the library schema.

Snapshots persist navigation, not domain stores, local form state, tasks, awaited
continuations, badges, accessibility identifiers, or sheet configuration. Restore
once per scene and reapply app-owned configuration. Use reports to diagnose
partial recovery. See the restoration skill for scope and migration details.

All families expose `setTransitionAnimation(_:)`. A synchronous
`withNavigationTransaction(animation: .disabled)` or `.custom(...)` scope applies
across a chain and restores on return/throw. It does not carry into a new task.
`setRoot(_:animation: nil)` inherits the configured default; use `.disabled`
for a per-operation suppression of implicit animations too.

## Test decisions without rendering

Link **ScaffoldingTesting** only into tests. Use `@MainActor` Swift Testing suites,
`activated()`, and public queries or typed `hierarchyContains(_:_:as:)` assertions.
Use `expecting:` when the test navigates; `descendant(ofType:)` finds an
already-created child when an app action performed the navigation.

```swift
let waiting = Task { await cards.present(.picker, awaiting: Item.self) }
guard await waitUntil({ cards.isPresentingModal }, timeout: .seconds(2)) else {
    waiting.cancel()
    return
}
cards.dismissPresentedModal()
#expect(await waiting.value == nil)
```

`waitUntil` uses deadlines and returns `Bool`; timeout records a test issue,
while cancellation returns false. Guard failure before awaiting work that cannot
finish. The old iteration-count overload is deprecated.

Test `shouldSelect` directly for guards; programmatic selection bypasses it.
Test task cancellation separately from dismissal: cancellation leaves UI in place.
Coordinator tests do not inspect view `@State` or `\.destination`. Library changes
to rendering also need checking in a running app.
