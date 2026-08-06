<div align="center">

# Scaffolding 目

**Macro-powered SwiftUI navigation that stays out of your way.**

[![Swift 6.2+](https://img.shields.io/badge/Swift-6.2+-F05138.svg?style=flat&logo=swift)](https://swift.org)
[![iOS 18+](https://img.shields.io/badge/iOS-18%2B-007AFF.svg?style=flat&logo=apple)](https://developer.apple.com/ios/)
[![macOS 15+](https://img.shields.io/badge/macOS-15%2B-000000.svg?style=flat&logo=apple)](https://developer.apple.com/macos/)
[![Swift Package Manager](https://img.shields.io/badge/SPM-compatible-brightgreen.svg?style=flat)](https://swift.org/package-manager/)

Define routes as functions. Get type-safe navigation for free.

</div>

---

## At a Glance

```swift
@Scaffoldable @Observable
final class HomeCoordinator: @MainActor FlowCoordinatable {
    var stack = FlowStack<HomeCoordinator>(root: .home)

    func home() -> some View { HomeView() }
    func detail(item: Item) -> some View { DetailView(item: item) }
    func settings() -> any Coordinatable { SettingsCoordinator() }
}
```

That's it. The `@Scaffoldable` macro generates a `Destinations` enum from your methods. No manual enums, no switch statements, no boilerplate.

```swift
coordinator.route(to: .detail(item: selectedItem))   // push
coordinator.present(.settings, as: .sheet)           // sheet (sub-flow)
coordinator.pop()
```

---

## Why Scaffolding?

| | `NavigationLink` | `NavigationStack(path:)` | **Scaffolding** |
|---|---|---|---|
| Navigation in UI layer | Yes | Yes | **No** |
| Type-safe destinations | No | Partial | **Yes** |
| Nested coordinator flows | No | Manual | **Built-in** |
| Modular architecture | Hard | Possible | **Natural** |
| Boilerplate | Low | Medium | **Minimal** |

If your app has a couple of screens, `NavigationLink` is fine. Once you have multiple flows, deep linking, or modular architecture — Scaffolding keeps things clean.

### When to use what

Scaffolding exists to give `NavigationStack` the **modularity** it lacks — coordinators, child coordinators, and `route(to:)` that compose across module boundaries. That's the core value.

For modals, pick the lightest tool that fits:

- **SwiftUI's native `.sheet(item:)` / `.fullScreenCover(item:)`** when the modal is a *single view* — a confirmation, an info dialog, a simple form. Keep it native; the view-side modifier is simpler and avoids coordinator overhead.
- **Scaffolding's `present(_:as:)`** when the modal is a *sub-flow* — a Login flow with email → password → done, a Settings hierarchy, anything with its own navigation. The presented coordinator gets a parent reference, can call `dismissCoordinator()` on itself, and delivers results back via `onComplete` callbacks.

Rule of thumb: **if the modal contains navigation, make it a coordinator and `present`. If it's a single-page view, use SwiftUI's native modifier.**

> ⚠ **Don't nest `NavigationStack` inside a flow.**
>
> `FlowCoordinatable` *is* the `NavigationStack`, so putting another one inside any of its destination views breaks navigation — SwiftUI doesn't compose `NavigationStack`s with each other, and the nested stack swallows the pushes that should belong to the parent flow.
>
> If a screen needs its own navigation hierarchy, route to a child `FlowCoordinatable` instead, or `present(_:as:)` a sub-flow modally. Each coordinator boundary creates a fresh `NavigationStack`, which is the only configuration SwiftUI handles correctly.

---

## Installation

Add Scaffolding via Swift Package Manager:

```
https://github.com/dotaeva/scaffolding.git
```

The package exposes two libraries: **Scaffolding** for your app target, and
**ScaffoldingTesting** — the test-only helpers described under
[Testing](#testing) — for your test target. Don't link `ScaffoldingTesting`
into an app target; it imports Swift Testing.

**Requirements:** iOS 18+ · macOS 15+ · tvOS 18+ · watchOS 11+ · macCatalyst 18+ · Swift 6.2 · Xcode 16+

### Agent skills

This repo doubles as a [Claude Code](https://claude.com/claude-code) plugin marketplace shipping five skills that teach coding agents the current API — coordinators, routing, `@Environment` values, state restoration, and testing. Install them with one command in your terminal:

```sh
claude plugin marketplace add dotaeva/scaffolding && claude plugin install scaffolding@scaffolding
```

Or, from inside a Claude Code session:

```
/plugin marketplace add dotaeva/scaffolding
/plugin install scaffolding@scaffolding
```

Add `--scope project` (CLI) if you'd rather commit the plugin to a single project than install it for your user. `claude plugin update scaffolding` pulls newer skills after a Scaffolding release; `claude plugin uninstall scaffolding` removes them.

Skills load on demand, so the standing cost is only the ~1.7k tokens of skill descriptions. For agents without plugin support, [`AGENTS.md`](AGENTS.md) covers the same ground in one file.

---

## Three Coordinator Types

### FlowCoordinatable — Navigation Stacks

Push, pop, and present modals. The workhorse of most apps.

```swift
@Scaffoldable @Observable
final class MainCoordinator: @MainActor FlowCoordinatable {
    var stack = FlowStack<MainCoordinator>(root: .home)

    func home() -> some View { HomeView() }
    func detail() -> some View { DetailView() }
    func profile() -> any Coordinatable { ProfileCoordinator() }
}
```

**API:**

| Method | Description |
|---|---|
| `route(to:policy:onDismiss:)` | Push a destination onto the stack |
| `present(_:as:policy:onDismiss:)` | Show a destination as a `.sheet` or `.fullScreenCover` |
| `pop()` / `pop(_:)` / `popToRoot()` | Pop the topmost / *n* destinations / everything-above-root |
| `popToFirst(_:)` / `popToLast(_:)` | Pop to a specific destination by `Meta` |
| `replaceLast(with:)` | Swap the top push, so back skips it |
| `setRoot(_:animation:)` | Replace the root destination |
| `dismissModal()` / `dismissAllModals()` | Close the top / every presented modal |
| `dismissCoordinator()` | Remove the whole coordinator from its parent |
| `depth` · `topDestination` · `isInStack(_:)` · `count(of:)` · `isPresentingModal` | Read the current stack |

Pass `policy: .distinct` to make a route a no-op when the same case is already on top (or already presented) — a one-word double-tap guard. Each navigation method that resolves a child coordinator also exposes `<T: Coordinatable>` overloads — a trailing closure or the flatter `expecting:` variant — for [deep linking](#deep-linking).

A flow can also start deep, without any routing calls:

```swift
var stack = FlowStack<HomeCoordinator>(root: .home, pushing: [.detail(item: item)])
```

### TabCoordinatable — Tab Bars

Each tab gets its own coordinator. Nest full navigation flows inside tabs.

```swift
@Scaffoldable @Observable
final class AppCoordinator: @MainActor TabCoordinatable {
    var tabItems = TabItems<AppCoordinator>(tabs: [.home, .profile, .search])

    func home() -> (any Coordinatable, some View) {
        (HomeCoordinator(), Label("Home", systemImage: "house"))
    }

    func profile() -> (any Coordinatable, some View) {
        (ProfileCoordinator(), Label("Profile", systemImage: "person"))
    }

    func search() -> (any Coordinatable, some View, TabRole) {
        (SearchCoordinator(), Label("Search", systemImage: "magnifyingglass"), .search)
    }
}
```

**API:**

| Method | Description |
|---|---|
| `selectFirstTab(_:)` / `selectLastTab(_:)` | Select a tab by `Meta` |
| `select(index:)` / `select(id:)` | Select by index or `UUID` |
| `appendTab(_:)` / `insertTab(_:at:)` | Add tabs dynamically |
| `removeFirstTab(_:)` / `removeLastTab(_:)` | Remove tabs |
| `setTabs(_:)` | Replace all tabs |
| `setBadge(_:for:)` / `badge(for:)` | Set or read a tab badge (`0` / `nil` clears) |
| `setTabBarVisibility(_:)` | Show or hide the native tab bar |
| `isInTabItems(_:)` | Check whether a tab is currently present |
| `present(_:as:policy:onDismiss:)` | Show a destination as a `.sheet` or `.fullScreenCover` |

Override `shouldSelect(tab:isReselection:)` to intercept **UI-driven** selection — guard a tab behind auth by returning `false`, or pop a flow to its root when the user re-taps its tab. Programmatic selection bypasses the hook, so redirecting from inside it can't recurse.

```swift
func shouldSelect(tab: Destinations.Meta, isReselection: Bool) -> Bool {
    if isReselection {
        if tab == .home {
            selectFirstTab(.home) { (home: HomeCoordinator) in home.popToRoot() }
        }
        return true     // ignored for re-taps — there's no change to veto
    }
    guard tab != .profile || session.isAuthenticated else {
        present(.login)
        return false
    }
    return true
}
```

Pass `visibility: .hidden` to `TabItems` and tab routes can drop their label views entirely — plain `any Coordinatable` / `some View` returns are auto-tracked too, so a custom bar built from `Destinations.Meta` and `selectFirstTab(_:)` replaces the native one.

### RootCoordinatable — State Switches

Swap the entire view hierarchy. Perfect for auth flows.

```swift
@Scaffoldable @Observable
final class AuthCoordinator: @MainActor RootCoordinatable {
    var root = Root<AuthCoordinator>(root: .login)

    func login() -> some View { LoginView() }
    func authenticated() -> any Coordinatable { MainAppCoordinator() }
}
```

One call flips the entire app state:

```swift
coordinator.setRoot(.authenticated)
```

`isRoot(_:)` reports which root is showing. `RootCoordinatable` also exposes `present(_:as:policy:onDismiss:)`, so a root coordinator can host a sheet or full-screen cover directly — the right home for cross-cutting UI (a What's New sheet, a debug panel) that isn't owned by any one flow.

---

## Full Example

```swift
@main
struct MyApp: App {
    @State private var appCoordinator = AppCoordinator()

    var body: some Scene {
        WindowGroup {
            appCoordinator.view
        }
    }
}

@Scaffoldable @Observable
final class AppCoordinator: @MainActor RootCoordinatable {
    var root = Root<AppCoordinator>(root: .unauthenticated)

    func unauthenticated() -> any Coordinatable { LoginCoordinator() }
    func authenticated() -> any Coordinatable { MainTabCoordinator() }
}

@Scaffoldable @Observable
final class MainTabCoordinator: @MainActor TabCoordinatable {
    var tabItems = TabItems<MainTabCoordinator>(tabs: [.home, .profile])

    func home() -> (any Coordinatable, some View) {
        (HomeCoordinator(), Label("Home", systemImage: "house"))
    }
    func profile() -> (any Coordinatable, some View) {
        (ProfileCoordinator(), Label("Profile", systemImage: "person"))
    }
}
```

---

## Advanced Usage

### Deep linking

Every navigation method that resolves a child coordinator
(`route`, `present`, `setRoot`, `appendTab`, `insertTab`, `popToFirst`,
`popToLast`, `selectFirstTab`, `selectLastTab`, `select(index:)`,
`select(id:)`) ships a `<T: Coordinatable>` overload with a trailing
closure that hands you a typed reference to the resolved child once the
route lands. Chain them to walk the tree from a cold launch:

```swift
appCoordinator.setRoot(.authenticated) { (tab: MainTabCoordinator) in
    tab.selectFirstTab(.profile) { (profile: ProfileCoordinator) in
        profile.route(to: .userDetail(id: userId))
    }
}
```

The closure only fires if the resolved destination can be cast to `T`,
so pick the concrete coordinator type that matches the route's return
signature. Every one of them has an `expecting:` sibling that returns the
child instead of taking a closure, which flattens long chains:

```swift
let tab = appCoordinator.setRoot(.authenticated, expecting: MainTabCoordinator.self)
let profile = tab?.selectFirstTab(.profile, expecting: ProfileCoordinator.self)
profile?.route(to: .userDetail(id: userId))
```

### Modals and Sheet Configuration

The **presenter** decides the chrome, so the same destination view can be a
medium sheet in one place and a full-screen cover in another:

```swift
present(.cardDetail(card: card), as: .sheet(detents: [.medium, .large]))
present(.freezeConfirm(card: card), as: .sheet(
    detents: [.medium],
    dragIndicator: .hidden,
    interactiveDismissDisabled: true      // the user must answer
))
present(.pinChange, as: .fullScreenCover)
```

`dismissModal()` closes the topmost modal from the presenter side and fires its
`onDismiss` exactly once — the counterpart to `dismissCoordinator()`, which the
*presented* coordinator calls on itself. It's also the only way to close a
view-only modal programmatically, and unlike `pop()` it never touches pushed
destinations.

### Async Navigation

Navigation that reads like a function call — push or present, then continue when
the user is done:

```swift
await routeAndWait(to: .categoryPicker)          // resumes when it pops
await presentAndWait(.pinChange, as: .fullScreenCover)

// …or with a result, nil when the user backed out:
guard let limit = await present(.limitPicker, awaiting: Decimal.self) else { return }
```

### Cross-Coordinator Results

Two ways to hand a value back, both without the presenter observing the child:

```swift
// 1. Constructor callback — the presenter installs the channel up front.
func buy(holding: Holding, onComplete: @escaping @MainActor (Order) -> Void) -> any Coordinatable {
    OrderCoordinator(holding: holding, onComplete: onComplete)
}

// 2. Return-on-dismiss, paired with `awaiting:` on the presenter.
func finish(_ amount: Decimal) {
    dismissCoordinator(returning: amount)
}
```

### Orienting in the Tree

Deep hierarchies stay legible without storing references to child coordinators:

```swift
flow.depth                  // pushes above the root, modals excluded
flow.topDestination         // Meta of the top push (or the root's)
coordinator.routeType       // .root / .push / .sheet / .fullScreenCover
coordinator.isPresentingModal
coordinator.ancestor(ofType: AppCoordinator.self)?.setRoot(.unauthenticated)
print(coordinator.hierarchyRoot.debugHierarchy())
```

`debugHierarchy()` prints the live tree — reach for it first when routing
misbehaves. It has no side effects; children that haven't been created yet are
reported as `(not yet created)` rather than materialised.

```
AppCoordinator [root]
  root .main → MainTabCoordinator [tab]
    tab[0] .home → HomeCoordinator [flow]
      root .transactions
      push .transaction
    tab[1]* .cards → CardsCoordinator [flow]
      root .cards
      sheet .limitPicker → LimitCoordinator [flow]
        root .presets
```

### State Restoration

Opt a coordinator's generated enum into `Codable` and the whole subtree can be
captured and replayed:

```swift
@Scaffoldable(codable: true) @Observable
final class HomeCoordinator: @MainActor FlowCoordinatable { /* … */ }

let data = try appCoordinator.captureNavigationState()   // opaque Data
try appCoordinator.restoreNavigationState(from: data)    // on a fresh tree
```

Coordinators that don't opt in (a route with a closure payload can't) still
work: their subtree restores at its initial position instead of failing, and
routes that no longer decode after an app update are skipped.

### Environment Access

Coordinators are automatically injected into the SwiftUI environment. The closest matching coordinator in the view hierarchy is used.

```swift
struct DetailView: View {
    @Environment(MainCoordinator.self) var coordinator

    var body: some View {
        Button("Next") {
            coordinator.route(to: .nextScreen)
        }
    }
}
```

### Destination Metadata

Each view can inspect how it was presented via the `\.destination` environment value:

```swift
@Environment(\.destination) private var destination

// destination.routeType        → .root, .push, .sheet, or .fullScreenCover
// destination.presentationType → effective presentation style
// destination.meta             → which generated case this destination is
```

A common use is a single reusable bar that adapts to context — back chevron when pushed, "Close" when presented as a sheet, nothing when it's the root:

```swift
struct AdaptiveTopBar: View {
    let title: String
    @Environment(\.destination) private var destination
    @Environment(\.dismiss)     private var dismiss

    var body: some View {
        HStack {
            switch destination.routeType {
            case .push:
                Button { dismiss() } label: { Image(systemName: "chevron.left") }
            case .sheet, .fullScreenCover:
                Button("Close") { dismiss() }
            case .root:
                Color.clear.frame(width: 24)
            }
            Spacer(); Text(title).font(.headline); Spacer()
            Color.clear.frame(width: 24, height: 1)
        }
        .padding(.horizontal, 16)
        .frame(height: 44)
    }
}
```

### Custom View Wrapping

Apply shared modifiers to all views in a coordinator:

```swift
@ScaffoldingIgnored
func customize(_ view: AnyView) -> some View {
    view
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { /* shared toolbar */ }
}
```

### Cross-Module Navigation

Mark a coordinator as `public` to expose its routes across modules — a natural fit for [modular architectures](https://docs.tuist.dev/en/guides/features/projects/tma-architecture).

---

## Testing

Navigation state lives on a plain `@Observable` class and every call mutates it synchronously, so the whole navigation layer is unit-testable — no host app, no rendered `NavigationStack`, no UI test. Link **ScaffoldingTesting** into your test target for the four helpers that make it ergonomic:

| Helper | What it does |
|---|---|
| `coordinator.activated()` | Resolves the initial root/tabs, which the framework normally does on first render. Without it, root-dependent reads come back empty. |
| `coordinator.descendant(ofType:)` | The typed handle on an already-created child — including one the code under test presented itself. |
| `coordinator.hierarchyContains(_:_:as:)` | Typed whole-tree assertion, instead of matching `debugHierarchy()` strings. |
| `await waitUntil { … }` | Spins the main actor until a condition holds, for the awaitable navigation API. |

```swift
import Testing
import Scaffolding
import ScaffoldingTesting
@testable import MyApp

@MainActor
@Suite("Home flow")
struct HomeFlowTests {
    @Test("RoutePolicy.distinct swallows a double tap")
    func distinctPolicySkipsDuplicatePush() {
        let home = HomeCoordinator().activated()

        home.open(Transaction.samples[0])
        home.open(Transaction.samples[0])

        #expect(home.count(of: .transaction) == 1)
    }

    @Test("a deep link walks root → tab → flow")
    func deepLink() throws {
        let app = AppCoordinator().activated()
        app.signIn()

        app.handle(try #require(URL(string: "myapp://holding/NVDA")))

        #expect(app.hierarchyContains(InvestCoordinator.self, .holding, as: .push))
    }

    @Test("an awaited sheet resumes with the picker's result")
    func awaitedResult() async {
        let cards = CardsCoordinator().activated()

        let picking = Task { await cards.changeLimit() }
        await waitUntil { cards.isPresentingModal }

        // present(_:awaiting:) hands back no coordinator — find it in the tree.
        cards.descendant(ofType: LimitCoordinator.self)?.finish(2_000)
        await picking.value

        #expect(cards.limit == 2_000)
    }
}
```

Assert with the orientation API (`depth`, `topDestination`, `isInStack(_:)`, `count(of:)`, `isPresentingModal`, `isRoot(_:)`, `badge(for:)`, `routeType`, `ancestor(ofType:)`), or read the structured tree with `hierarchySnapshot()` — the same snapshot `debugHierarchy()` renders, and what the helpers above are built on. Tab guards are just methods: `#expect(!tabs.shouldSelect(tab: .invest, isReselection: false))`.

The demo app ships [44 such tests](Example/Demo/Tests) covering pushes and policies, modals and presenter-side dismissal, tab guards and badges, deep links, cross-coordinator results, and state restoration.

---

## Macros Reference

| Macro | Target | Purpose |
|---|---|---|
| `@Scaffoldable(injectsCoordinator: Bool = true, codable: Bool = false)` | Class | Generates the `Destinations` enum (and its `Meta`) from the class's methods. `injectsCoordinator: false` opts the coordinator out of automatic environment injection; `codable: true` makes `Destinations` `Codable` for [state restoration](#state-restoration). |
| `@ScaffoldingIgnored` | Method | Excludes a method whose return type *is* auto-tracked from destination generation (e.g. `customize(_:)` or a shared view-builder helper). Properties, `Void` methods, and concrete return types are never tracked, so they don't need it. |

---

## Example Project

[`Example/Demo`](Example/Demo) is a banking-style app that exercises the whole API surface — a root coordinator with an auth swap, a tab coordinator with a custom glass tab bar and a gated tab, four independent flows, sheet configuration, awaited results, deep links, snapshot save/restore, and the unit tests above. It's a plain Xcode project with no generators or extra tooling:

```sh
open Example/Demo/Demo.xcodeproj
```

⌘R runs the app, ⌘U runs the tests.

A multi-module example using [Tuist](https://github.com/tuist/tuist) and The Modular Architecture lives [here](https://github.com/dotaeva/zen-example-tma).

---

<div align="center">

**MIT License**

</div>
