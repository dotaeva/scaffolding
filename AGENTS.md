# Scaffolding — Agent Guide

A reference for LLM coding agents (and humans) writing SwiftUI code with the **Scaffolding** library. Read this before generating navigation code in any project that uses Scaffolding.

The single most important idea: **Scaffolding's value is modular navigation across coordinator boundaries. The win is separation of concerns — UI views never own navigation state.** If you produce code that mixes navigation state into views, you've lost the reason to use the library.

---

## Why Scaffolding exists

SwiftUI's `NavigationStack(path:)` works for a single, self-contained screen graph. It breaks down once an app has:

- multiple feature modules that need to push into each other,
- destination types defined in different modules,
- coordinator-driven flows (login, onboarding, settings sheets),
- programmatic navigation that has to compose across module boundaries.

`NavigationStack` keeps navigation **inside the view tree**. That's the design constraint Scaffolding is built to escape. A `FlowCoordinatable` *is* a `NavigationStack` — but its destinations live on the coordinator (a plain Swift class), the macro generates the destination enum, and child coordinators slot in as routes without the view tree knowing.

If you find yourself reaching for `NavigationStack(path:)` inside a Scaffolding project, **stop**. There is almost certainly a coordinator-side answer.

---

## The hard rule: do not nest `NavigationStack`

`FlowCoordinatable` already wraps a `NavigationStack` internally. SwiftUI does **not** compose `NavigationStack`s with each other — the inner stack swallows pushes that should belong to the outer one, and `route(to:)` stops doing what you expect.

**Never put a `NavigationStack` inside any view returned by a `FlowCoordinatable` route function.** Not in the root view, not in a pushed detail view, not in a customise wrapper.

If a screen needs its own navigation hierarchy, give it a child coordinator:

```swift
// ❌ Wrong — nested NavigationStack breaks routing.
func detail(item: Item) -> some View {
    NavigationStack {       // ← don't.
        DetailRoot(item: item)
    }
}

// ✅ Right — child FlowCoordinator gets its own NavigationStack at the
//    coordinator boundary, where SwiftUI handles it correctly.
func detail(item: Item) -> any Coordinatable {
    DetailCoordinator(item: item)
}
```

The same applies to anything that wraps SwiftUI's stack: `NavigationView`, `NavigationSplitView`, custom containers that hold a `NavigationPath`. They all conflict.

---

## Picking a navigation primitive

When a user-facing transition needs to happen, use this decision tree:

```
Is it a push/pop on the current stack?
├─ Yes → coordinator.route(to: .someDestination)
│
└─ No, it's a modal.
   │
   Is the modal a single screen — confirmation, info dialog,
   simple form, picker?
   │
   ├─ Yes → SwiftUI native: .sheet(item:) / .fullScreenCover(item:)
   │
   └─ No, the modal contains its own navigation flow
      (multiple steps, push, dismiss-with-result, etc.).
      │
      → coordinator.present(.flow, as: .sheet)
        (returns a child coordinator from the route function)
```

### Concretely

| You want… | Use |
|---|---|
| Push a screen onto the current flow | `coordinator.route(to: .screen(args:))` |
| Pop the current screen | `coordinator.pop()` |
| Pop everything above the root | `coordinator.popToRoot()` |
| Show a confirmation dialog | SwiftUI's `.alert` / `.confirmationDialog` |
| Show a one-screen sheet (simple form, info) | SwiftUI's `.sheet(item:)` |
| Show a multi-step sub-flow | `coordinator.present(.subflow, as: .sheet)` |
| Show a full-screen sub-flow | `coordinator.present(.subflow, as: .fullScreenCover)` |
| Dismiss a modal you presented (presenter side, any coordinator type) | `coordinator.dismissModal()` |
| Intercept a tab tap (guard, redirect, pop-to-root on re-tap) | override `shouldSelect(tab:isReselection:)` on the `TabCoordinatable` |
| Atomically replace the entire view hierarchy (auth, onboarding) | `appCoordinator.setRoot(.authenticated)` (on a `RootCoordinatable`) |
| Switch tabs programmatically | `tabCoordinator.selectFirstTab(.home)` |
| Replace the system tab bar with your own UI | `TabItems(tabs:, visibility: .hidden)` + custom bar view (see *Custom tab bar*) |

Stay native for view-only modals. The native modifier is lighter, requires no coordinator boundary, and avoids the overhead of an extra `Destinations` case.

---

## Coordinator anatomy

```swift
@MainActor @Observable @Scaffoldable
final class HomeCoordinator: @MainActor FlowCoordinatable {
    // Required: the observable container that owns the stack.
    var stack = FlowStack<HomeCoordinator>(root: .home)

    // Routes — each becomes a `Destinations` enum case.
    func home()             -> some View         { HomeView() }
    func detail(item: Item) -> some View         { DetailView(item: item) }
    func settings()         -> any Coordinatable { SettingsCoordinator() }

    // Optional helpers. Void return type ⇒ never tracked by the macro —
    // no @ScaffoldingIgnored needed (or wanted) here.
    func openDetail(_ item: Item) {
        route(to: .detail(item: item))
    }
}
```

### Auto-tracked return types

The `@Scaffoldable` macro scans the coordinator's **functions** — and only functions; stored/computed properties, `init`, and `deinit` are never scanned — and generates a `Destinations` enum case for every function whose return type is one of:

| Return type | What it generates |
|---|---|
| `some View` | A view destination |
| `any Coordinatable` | A child-coordinator destination |
| `(any Coordinatable, some View)` | Tab: coordinator + label view |
| `(some View, some View)` | Tab: view-only + label view |
| `(any Coordinatable, TabRole)` | Tab: coordinator + role |
| `(some View, TabRole)` | Tab: view-only + role |
| `(any Coordinatable, some View, TabRole)` | Tab: coordinator + label + role |
| `(some View, some View, TabRole)` | Tab: view-only + label + role |

Anything else is skipped **automatically**: `Void` functions, concrete return types — including a **concrete** coordinator like `-> LoginCoordinator` — closures, generic types (`Foo<Bar>`), arrays, and any tuple shape not in the table. None of it needs an annotation.

For a child coordinator the return type **must** be `any Coordinatable` (the existential); views must return `some View`:

```swift
// ❌ Won't be picked up — concrete type.
func login() -> LoginCoordinator { LoginCoordinator() }

// ✅ Existential — macro generates a `.login` case.
func login() -> any Coordinatable { LoginCoordinator() }
```

### `@ScaffoldingIgnored` — when to use it, and when not to

**Do not** put `@ScaffoldingIgnored` on everything that isn't a route. The macro already ignores:

```swift
// ❌ All of these annotations are redundant noise — none of these
//    declarations is tracked in the first place. Remove the attribute.
@ScaffoldingIgnored var session: AuthToken?                  // properties: never scanned
@ScaffoldingIgnored func openDetail(_ item: Item) {          // returns Void: never tracked
    route(to: .detail(item: item))
}
@ScaffoldingIgnored func makeHandler() -> () -> Void { ... } // closure return: never tracked
```

Use it **only** when a function's return type is in the auto-tracked table but the function isn't a destination:

```swift
// ✅ Genuinely needed — `customize` returns `some View`, so the macro
//    would otherwise emit a bogus `.customize` destination.
@ScaffoldingIgnored
func customize(_ view: AnyView) -> some View {
    view
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { /* shared toolbar */ }
}

// ✅ Shared view-builder helper — returns `some View` but isn't a route.
@ScaffoldingIgnored
func emptyState(message: String) -> some View { ... }

// ✅ Factory helper returning a coordinator that isn't routed to directly.
@ScaffoldingIgnored
func makeDebugCoordinator() -> any Coordinatable { ... }
```

There is no opt-in tracking attribute. Auto-tracking by return type plus exclusion via `@ScaffoldingIgnored` is the only mechanism.

---

## Three coordinator protocols

Pick by user-facing structure, not by mood.

| Protocol | Use when |
|---|---|
| `FlowCoordinatable` | Push/pop navigation. The workhorse. Wraps a `NavigationStack`. |
| `TabCoordinatable` | Tab bar where each tab is independent. Each tab's content is its own coordinator. |
| `RootCoordinatable` | Atomic root swap: auth flow ↔ main app, onboarding ↔ home. The whole tree is replaced when `setRoot(_:)` is called. |

A typical app uses all three:

```
AppCoordinator (Root)
├── LoginCoordinator (Flow)              ← unauthenticated
└── MainTabCoordinator (Tab)             ← authenticated
    ├── HomeCoordinator (Flow)
    │   └── DetailView (push) + SettingsCoordinator (modal)
    └── ProfileCoordinator (Flow)
        └── EditProfileView (push)
```

`setRoot` flips between the two `App` children. The tab coordinator owns the home/profile flows. Each flow handles its own pushes and modals.

---

## Separation of concerns — the discipline

This is the part that makes Scaffolding worth using. If you violate it, you've reintroduced the problems Scaffolding was built to solve.

### Views never own navigation state

- ❌ A view does **not** hold `@State path: [SomeType]`.
- ❌ A view does **not** hold `@State isPresented = false` for a sheet that's part of the flow.
- ❌ A view does **not** receive `@Binding path: [SomeType]` to pop.
- ✅ A view reads its coordinator from `@Environment` and calls `coordinator.route(to:)`, `coordinator.pop()`, `coordinator.present(_:as:)` etc.

### Coordinators don't know how their views render

- ❌ A coordinator does **not** import SwiftUI just to construct a `NavigationStack`.
- ❌ A coordinator does **not** read `@Environment` (it's not a View).
- ✅ A coordinator's job is route declaration + state mutation. The macro and the framework wire the views to the stack.

### Modules expose coordinators, not views

In a multi-module app, the right unit of import is the coordinator type:

```swift
import HomeFeature

let home = HomeCoordinator()
appRoot.setRoot(.home(home))
```

Other modules don't need to know what views are inside, what destinations exist, or how the flow is structured. They hold a coordinator reference and route to its surface.

### Result delivery between coordinators

When a presented coordinator needs to return a value, take the callback in the route function:

```swift
// AppCoordinator
func login(onComplete: @escaping @MainActor (AuthToken) -> Void) -> any Coordinatable {
    LoginCoordinator(onComplete: onComplete)
}

func startLogin() {
    present(.login(onComplete: { [weak self] token in
        self?.session = token
    }), as: .sheet)
}
```

Inside `LoginCoordinator`, when the user finishes:

```swift
func submit() {
    onComplete(AuthToken(...))    // deliver result
    dismissCoordinator()          // dismiss self
}
```

The presenter doesn't observe the presented coordinator's state. The presented coordinator hands a result back through the closure it was constructed with, then dismisses itself. Clean boundaries.

### `dismissCoordinator()` semantics

`dismissCoordinator()` is called on the coordinator being removed. It pops the **whole coordinator** off its parent — not a screen. For a sheet/cover, that closes the modal. For a pushed child coordinator, that removes the child and any of its own pushed destinations.

To pop a single screen within the same flow, use `pop()`. The two are not interchangeable.

---

## Quick patterns

### A flow with a sheet that's a sub-flow

```swift
@MainActor @Observable @Scaffoldable
final class HomeCoordinator: @MainActor FlowCoordinatable {
    var stack = FlowStack<HomeCoordinator>(root: .home)

    func home() -> some View { HomeView() }
    func detail(item: Item) -> some View { DetailView(item: item) }
    func settings() -> any Coordinatable { SettingsCoordinator() }

    func openSettings() {
        present(.settings, as: .sheet)
    }
}
```

### A flow with a one-screen view-only sheet

```swift
// Coordinator: no `.confirmation` route — that's an internal view detail.
@MainActor @Observable @Scaffoldable
final class HomeCoordinator: @MainActor FlowCoordinatable {
    var stack = FlowStack<HomeCoordinator>(root: .home)
    func home() -> some View { HomeView() }
}

// View: native sheet + local `@State`. The confirmation isn't a flow,
// it's a single screen — keep it native.
struct HomeView: View {
    @Environment(HomeCoordinator.self) private var coordinator
    @State private var pendingDelete: Item?

    var body: some View {
        List(items) { item in
            Button(item.name) { pendingDelete = item }
        }
        .sheet(item: $pendingDelete) { item in
            ConfirmDeleteSheet(item: item) {
                /* perform delete */
            }
        }
    }
}
```

### Atomic auth swap

```swift
@MainActor @Observable @Scaffoldable
final class AppCoordinator: @MainActor RootCoordinatable {
    var root = Root<AppCoordinator>(root: .unauthenticated)

    func unauthenticated() -> any Coordinatable { LoginCoordinator() }
    func authenticated()   -> any Coordinatable { MainTabCoordinator() }

    func signIn()  { setRoot(.authenticated) }
    func signOut() { setRoot(.unauthenticated) }
}
```

### Deep linking with the typed `<T: Coordinatable>` overloads

Every navigation method that resolves a child coordinator (`route`, `present`, `setRoot`, `appendTab`, `insertTab`, `popToFirst`, `popToLast`, `selectFirstTab`, `selectLastTab`, `select(index:)`, `select(id:)`) ships a `<T: Coordinatable>` overload that fires a trailing closure with a **typed handle on the resolved child** once the route lands. Chain them to walk the tree from a cold launch:

```swift
@Scaffoldable @Observable
final class AppCoordinator: @MainActor RootCoordinatable {
    var root = Root<AppCoordinator>(root: .unauthenticated)

    func unauthenticated() -> any Coordinatable { LoginCoordinator() }
    func authenticated()   -> any Coordinatable { MainTabCoordinator() }

    /// Land on the user's profile from a URL / push / quick action.
    func openProfile(userId: Int) {
        setRoot(.authenticated) { (tab: MainTabCoordinator) in
            tab.selectFirstTab(.profile) { (profile: ProfileCoordinator) in
                profile.route(to: .userDetail(id: userId))
            }
        }
    }
}
```

Hook the entry point to whatever launched the app:

```swift
WindowGroup {
    coordinator.view
        .onOpenURL { url in
            if let userId = parseUserURL(url) {
                coordinator.openProfile(userId: userId)
            }
        }
}
```

Three rules when generating deep-link code:

- The typed closure only fires if the resolved child can be cast to `T`. Pick the concrete coordinator type that matches the route's return signature — for `func authenticated() -> any Coordinatable { MainTabCoordinator() }`, the closure parameter must be `MainTabCoordinator`.
- Don't try to deep-link by storing references to child coordinators outside the chain. The typed overloads exist so you don't have to — they hand you the right reference at the right time.
- Don't deep-link in pieces from views. Deep-linking lives on the coordinator (or on whatever orchestrator owns the URL/push entry point), and views call into it. A view that dispatches multiple `route(to:)` / `setRoot(_:)` calls in sequence is a smell.

### Tab bar with independent flows

```swift
@MainActor @Observable @Scaffoldable
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

### Intercepting tab selection

Override `shouldSelect(tab:isReselection:)` on a `TabCoordinatable` to intercept **UI-driven** tab changes (taps on the tab bar). Return `false` to keep the current tab; perform your own navigation instead if needed. When the user re-taps the already-selected tab, the hook fires with `isReselection == true` (the return value is ignored — there's no change to veto). Programmatic selection (`selectFirstTab`, `select(index:)`, …) bypasses the hook, so redirecting from inside it doesn't recurse.

```swift
@MainActor @Observable @Scaffoldable
final class MainTabCoordinator: @MainActor TabCoordinatable {
    var tabItems = TabItems<MainTabCoordinator>(tabs: [.home, .profile])

    func home() -> (any Coordinatable, some View) {
        (HomeCoordinator(), Label("Home", systemImage: "house"))
    }
    func profile() -> (any Coordinatable, some View) {
        (ProfileCoordinator(), Label("Profile", systemImage: "person"))
    }

    // Returns Bool ⇒ never tracked by the macro — no @ScaffoldingIgnored needed.
    func shouldSelect(tab: Destinations.Meta, isReselection: Bool) -> Bool {
        // Re-tap of the selected tab → pop its flow to the root.
        if isReselection {
            if tab == .home {
                selectFirstTab(.home) { (home: HomeCoordinator) in home.popToRoot() }
            }
            return true
        }
        // Guard a tab behind authentication.
        if tab == .profile && !session.isAuthenticated {
            present(.login)   // show login instead of switching
            return false
        }
        return true
    }
}
```

### Custom tab bar

To replace the system tab bar with your own UI, stay on `TabCoordinatable` — don't hand-roll tab state in a view. Three pieces:

1. **Hide the native bar** — pass `visibility: .hidden` to the `TabItems` initializer (or call `setTabBarVisibility(.hidden)` later).
2. **Omit the label views.** The `some View` label in the tab tuple only feeds the native tab bar. With a custom bar it's dead weight — tab routes can return plain `any Coordinatable` (or `some View` for a view-only tab) instead of `(any Coordinatable, some View)`. Both are auto-tracked, so the macro still generates the `.home` / `.profile` cases; the tab simply has no native label.
3. **Build the bar from the macro-generated values.** The bar is an ordinary view: it reads the coordinator from `@Environment`, renders a button per `Destinations.Meta` case, drives selection with `selectFirstTab(_:)`, and derives the selected state from `tabItems.selectedTab`. Badges come from `badge(for:)`. Attach it in `customize(_:)`, which wraps the whole `TabView`.

```swift
@MainActor @Observable @Scaffoldable
final class MainTabCoordinator: @MainActor TabCoordinatable {
    var tabItems = TabItems<MainTabCoordinator>(
        tabs: [.home, .profile],
        visibility: .hidden          // native bar off
    )

    // No native bar → no label views. Plain returns still generate the cases.
    func home()    -> any Coordinatable { HomeCoordinator() }
    func profile() -> any Coordinatable { ProfileCoordinator() }

    @ScaffoldingIgnored
    func customize(_ view: AnyView) -> some View {
        view.safeAreaInset(edge: .bottom) { CustomTabBar() }
    }
}

struct CustomTabBar: View {
    @Environment(MainTabCoordinator.self) private var coordinator

    var body: some View {
        HStack {
            tabButton(.home,    icon: "house")
            tabButton(.profile, icon: "person")
        }
    }

    private func tabButton(
        _ tab: MainTabCoordinator.Destinations.Meta,
        icon: String
    ) -> some View {
        Button {
            coordinator.selectFirstTab(tab)
        } label: {
            Image(systemName: icon)
                .foregroundStyle(isSelected(tab) ? Color.accentColor : .secondary)
        }
    }

    private func isSelected(_ tab: MainTabCoordinator.Destinations.Meta) -> Bool {
        coordinator.tabItems.tabs
            .first { $0.id == coordinator.tabItems.selectedTab }
            .flatMap { $0.meta as? MainTabCoordinator.Destinations.Meta } == tab
    }
}
```

One caveat: taps on a custom bar go through `selectFirstTab(_:)`, which is **programmatic** selection — `shouldSelect(tab:isReselection:)` is not consulted. If you need guarding or re-tap behavior, call the hook yourself from the button action:

```swift
Button {
    let isReselection = isSelected(tab)
    if coordinator.shouldSelect(tab: tab, isReselection: isReselection) && !isReselection {
        coordinator.selectFirstTab(tab)
    }
}
```

### Presenter-side modal dismissal

`present(_:as:)` is paired with `dismissModal()`, available on **every** coordinator type. It removes the most recently presented modal and fires its `onDismiss` exactly once — equivalent to the user swiping the sheet away. Use it when the **presenter** decides the modal is done; the presented coordinator itself still uses `dismissCoordinator()`. This also covers view-only modals (a `some View` route presented modally), which have no coordinator to call `dismissCoordinator()` on.

```swift
appCoordinator.present(.whatsNew)          // some View route — no child coordinator
appCoordinator.dismissModal()              // presenter closes it later
```

On a `FlowCoordinatable`, `dismissModal()` removes only the topmost modal and never touches pushed destinations — prefer it over `pop()` for closing modals: `pop()` removes whatever is last on the stack (and dismisses the whole coordinator when the stack is empty), while `dismissModal()` is a safe no-op when nothing is presented.

---

## Orienting in a nested hierarchy

Deep trees (root → tabs → flows → presented sub-flows) make it easy to lose track of which coordinator owns the current screen. Don't guess — Scaffolding has explicit orientation tools.

### Which coordinator do I call?

- **From a view:** the nearest coordinator via `@Environment(HomeCoordinator.self)`. Every *ancestor* coordinator is injected too — `@Environment(AppCoordinator.self)` works from any depth. Prefer the nearest one; reach for an ancestor only for actions that genuinely belong to it (root swaps, tab switching).
- **From a coordinator, upward:** `ancestor(ofType:)` walks the `parent` chain to this coordinator's nearest ancestor of that type:

  ```swift
  // A flow deep in the tree exposes an action that belongs to the app root.
  func signOut() {
      ancestor(ofType: AppCoordinator.self)?.setRoot(.unauthenticated)
  }
  ```

- **From a coordinator, downward:** stay typed through the deep-link trailing closures / `expecting:` overloads (see Deep linking). Never store references to child coordinators.

### Where am I?

| Question | API |
|---|---|
| How was this **coordinator** presented? | `coordinator.routeType` — `.root` / `.push` / `.sheet` / `.fullScreenCover`; `routeType.isModal` collapses the modal cases |
| How was this **screen** reached? (in a view) | `@Environment(\.destination).routeType` |
| How deep is the flow? | `flow.depth` — pushed count above root, modals excluded |
| What's on top? | `flow.topDestination` — `Destinations.Meta` of the top push, or the root's |
| Is a case already in the stack? | `flow.isInStack(.detail)`, `flow.count(of: .detail)` |
| Is a modal up? | `coordinator.isPresentingModal` (any coordinator type) |

The two `routeType`s answer different questions and can differ for the same screen: a view pushed inside a sheet-presented flow reads `.push` from `\.destination`, while its flow coordinator reads `.sheet`.

### When routing misbehaves, print the tree first

```swift
print(coordinator.hierarchyRoot.debugHierarchy())   // whole tree from anywhere
```

```
AppRootCoordinator [root]
  root .main → MainTabCoordinator [tab]
    tab[0]* .home → HomeFlowCoordinator [flow]
      root .home
      push .settings
      sheet .sheetFlow → LeafFlowCoordinator [flow]
        root .leaf
```

`hierarchyRoot` is the topmost coordinator of the tree; `debugHierarchy()` is a side-effect-free snapshot (uncreated children are reported as `(not yet created)`, never materialised). It answers "who owns what" immediately — verify your mental model of the tree against it before changing navigation code.

---

## Previews

`#Preview` and `@Scaffoldable` are both compile-time macros, but they don't compose at runtime the way you might expect. Three rules — follow them when generating preview code in a Scaffolding project.

### 1. Don't seed an initial route in `#Preview`

The `Destinations` enum lives on the coordinator type, and the `FlowStack` is constructed with a literal root case. The macro does **not** synthesise an `init(initialRoute:)`, so there's nothing to call:

```swift
// ❌ Doesn't compile — no such initialiser exists.
#Preview {
    HomeCoordinator(initialRoute: .detail(item: planet)).view
}
```

Preview the coordinator at its real root, or render the leaf view directly:

```swift
// ✅ Coordinator at root.
#Preview("Home") {
    HomeCoordinator().view
}

// ✅ Leaf view rendered alone — inject what it reads from @Environment.
#Preview("DetailView · pushed") {
    DetailView(item: .earth)
        .environment(HomeCoordinator())
}
```

### 2. Inject the coordinator any view reads via `@Environment`

At runtime Scaffolding installs each coordinator in the environment of every view it manages. In `#Preview` you usually render a view *outside* that chain, so any `@Environment(SomeCoordinator.self)` lookup falls back to a default (or crashes on Swift 6 strict concurrency). Always pass it explicitly:

```swift
// ✅ The view gets the same env value it would at runtime.
SomeScreen().environment(HomeCoordinator())
```

### 3. `\.destination` is unreliable in previews

`\.destination` is set by the framework when it materialises a destination through `route(to:)` / `present(_:as:)` / `setRoot(_:)`. A view rendered alone in `#Preview` is not materialised through that path, so its `destination.routeType`, `destination.presentationType`, and `destination.meta` read as the default (`.root`) — not the value you'd see when the screen is actually pushed or presented.

Don't write previews whose correctness depends on those properties matching runtime. If you need to *visually* preview a pushed-state, render the parent coordinator at root and use the deep-link/seeding flow your app already exposes (a function on the coordinator that performs the routes you want), not a preview-only initialiser.

### Adaptive bars from `\.destination` (the runtime side)

At runtime the destination environment is reliable, and its public properties are exactly what you need to write a single reusable chrome that adapts to push / sheet / cover / root. This is the canonical use of `destination.routeType`:

```swift
import SwiftUI
import Scaffolding

/// Reusable top bar that adapts to how the current screen was reached.
struct AdaptiveTopBar: View {
    let title: String

    @Environment(\.destination) private var destination
    // Scaffolding wraps NavigationStack, so SwiftUI's native dismiss
    // works for both pops (push) and modal dismissals.
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
            Spacer()
            Text(title).font(.headline)
            Spacer()
            Color.clear.frame(width: 24, height: 1)
        }
        .padding(.horizontal, 16)
        .frame(height: 44)
    }
}
```

The same view, used as a root, a pushed detail, and a presented sheet, renders three different leading controls — without the bar knowing anything about the surrounding flow. Switch on `destination.meta` (the macro emits a `Meta` enum alongside `Destinations`) when the same view renders different *layouts* depending on which route reached it.

---

## Testing

A coordinator is a plain `@MainActor @Observable` class and every navigation call mutates its state **synchronously**, so the entire navigation layer is unit-testable: no host app, no rendered `NavigationStack`, no UI test, no view-inspection library. Test the shipping coordinator directly — don't invent a test double for it.

This is the payoff of the discipline above. If navigation logic can't be reached from a test, the cause is almost always state that leaked into a view.

The package ships a second library, **ScaffoldingTesting**, for the test target only (it imports Swift Testing — never link it into an app target). Four helpers:

| Helper | Use it for |
|---|---|
| `coordinator.activated()` | Resolving the initial root/tabs before asserting. **Required** — see below. |
| `coordinator.descendant(ofType:)` / `descendants(ofType:)` | A typed handle on an already-created child, including one the code under test presented itself. Never materialises anything. |
| `coordinator.hierarchyContains(_:_:)` / `(_:_:as:)` | Typed whole-tree assertions instead of `debugHierarchy()` string matching. |
| `await waitUntil { … }` | Letting a `Task` started by the code under test run before asserting. |

```swift
import Testing
import Scaffolding
import ScaffoldingTesting
@testable import MyApp

@MainActor                          // coordinators are MainActor-isolated
@Suite("Home flow")
struct HomeFlowTests {
    @Test("opening a transaction pushes one screen")
    func openPushes() {
        let home = HomeCoordinator().activated()

        home.open(Transaction.samples[0])

        #expect(home.depth == 1)
        #expect(home.topDestination == .transaction)
    }
}
```

### Always activate first

`FlowStack` / `Root` / `TabItems` resolve their initial destinations lazily — the first time the framework touches `view`, `anyStack`, `anyRoot`, or `anyTabItems`, which at runtime is the first render. A test renders nothing, so without `activated()` the root is still unresolved and every root-dependent read (`topDestination`, `isRoot(_:)`, `debugHierarchy()`) comes back empty. Pushes and presentations work without it; assertions about the root don't.

### What to assert on

The orientation API from *Where am I?* is the assertion surface: `depth`, `topDestination`, `isInStack(_:)`, `count(of:)`, `isPresentingModal`, `isRoot(_:)`, `isInTabItems(_:)`, `badge(for:)`, `routeType`, `ancestor(ofType:)`, `hierarchyRoot`. For multi-step navigation, assert the shape of the tree:

```swift
app.handle(URL(string: "myapp://holding/NVDA")!)

#expect(app.hierarchyContains(InvestCoordinator.self, .holding, as: .push))
#expect(app.hierarchyContains(MainTabCoordinator.self, .invest, as: .tab(index: 2, isSelected: true)))
```

`hierarchySnapshot()` (in the main library) returns that tree as `[HierarchyNode]` — `role`, `meta`, `coordinator`, `children` — when a test or a debug UI needs more than a yes/no. Never assert on framework internals (`Destination`, `pushType`, `resolution`) or on SwiftUI output.

### Reaching a child coordinator

Two ways, and they answer different questions:

- **In production code** — the `expecting:` overloads (or typed trailing closures) hand the child over at the moment the route lands: `let picker = cards.present(.limitPicker, expecting: LimitCoordinator.self)`.
- **In a test** — `descendant(ofType:)` finds a child the code under test created on its own, which is the only way in when the action awaits its own presentation:

```swift
let picking = Task { await cards.changeLimit() }   // wraps present(_:awaiting:)
await waitUntil { cards.isPresentingModal }

cards.descendant(ofType: LimitCoordinator.self)?.finish(2_000)
await picking.value

#expect(cards.limit == 2_000)
```

Don't store child coordinator references on a coordinator to make it testable — that breaks the ownership model. Returning the child from an action (`@discardableResult` + `expecting:`) is fine and often the clearest seam.

### Modals, guards, and results

```swift
// Presenter-side dismissal, and the .distinct policy swallowing a double tap.
cards.openDetail(card)
cards.openDetail(card)
#expect(cards.count(of: .cardDetail) == 1)
cards.resolveFreeze(card, freeze: true)
#expect(!cards.isPresentingModal)

// shouldSelect is an ordinary method — call it the way the tab bar does.
#expect(!tabs.shouldSelect(tab: .invest, isReselection: false))
#expect(tabs.isPresentingModal)     // the gate it presented instead
#expect(tabs.selectedIndex == 0)    // selection never moved
```

Programmatic tab selection bypasses `shouldSelect`, so a test that calls `selectFirstTab` is testing selection, not the guard.

### Awaitable navigation

`routeAndWait`, `presentAndWait`, and `present(_:awaiting:)` suspend until the destination leaves. Drive them from a `Task`, then resolve them from the test body:

```swift
let picking = Task { await cards.present(.limitPicker, awaiting: Decimal.self) }
await waitUntil { cards.isPresentingModal }

cards.dismissModal()                            // stands in for a swipe-down
#expect(await picking.value == nil)             // cancellation path
```

### Don't test

`\.destination` reads as its default in a unit test for the same reason it does in a `#Preview` (nothing was materialised through the framework), views' rendering, or anything that requires poking a view's `@State` to drive navigation — that last one is a design bug to fix, not a test to write.

---

## Common mistakes — what NOT to generate

### 1. Wrapping a destination view in `NavigationStack`

```swift
// ❌ Breaks `route(to:)` from the parent flow.
func detail(item: Item) -> some View {
    NavigationStack {
        DetailScreen(item: item)
    }
}
```

Drop the `NavigationStack`. The parent flow already provides one.

### 2. Blanket `@ScaffoldingIgnored` on non-route members

```swift
// ❌ Redundant — properties and Void-returning helpers are never tracked.
@ScaffoldingIgnored var stack = FlowStack<HomeCoordinator>(root: .home)
@ScaffoldingIgnored func openSettings() { present(.settings, as: .sheet) }
```

The macro only considers functions whose return type is in the auto-tracked table (`some View`, `any Coordinatable`, or a tab tuple). Everything else — properties, `Void` methods, concrete types, closures, generics — is ignored automatically. Reserve `@ScaffoldingIgnored` for the cases that genuinely need it: `customize(_:)`, shared view-builder helpers returning `some View`, and non-route coordinator factories.

### 3. Holding navigation state in a view

```swift
// ❌ Defeats the point of coordinators.
struct HomeView: View {
    @State private var pushedDetail: Item?
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            List(...)
                .navigationDestination(item: $pushedDetail) { ... }
                .sheet(isPresented: $showSettings) { ... }
        }
    }
}
```

Move pushes to the coordinator (`coordinator.route(to: .detail(item:))`). Keep the sheet only if it's a true single-screen view-only modal.

### 4. `route(to:as: .sheet)` (old API)

That API was split. Push uses `route(to:)`. Modals use `present(_:as:)`. There is no `as:` parameter on `route` anymore.

```swift
// ❌ Old, no longer exists.
coordinator.route(to: .settings, as: .sheet)

// ✅ Correct.
coordinator.present(.settings, as: .sheet)
```

### 5. Reaching for `NavigationLink` to push

```swift
// ❌ Couples the row to navigation; breaks under modular coordinators.
NavigationLink(value: planet) { Label(planet.name, ...) }
```

```swift
// ✅ Plain Button + coordinator call.
Button {
    coordinator.route(to: .detail(item: planet))
} label: {
    Label(planet.name, ...)
}
```

### 6. Calling `dismissCoordinator()` to close a single screen

```swift
// ❌ Dismisses the entire coordinator, not just the current screen.
struct DetailView: View {
    @Environment(HomeCoordinator.self) private var coordinator
    var body: some View {
        Button("Back") { coordinator.dismissCoordinator() }
    }
}
```

Use `coordinator.pop()` — or SwiftUI's `@Environment(\.dismiss)`, which works because Scaffolding wraps `NavigationStack`. Save `dismissCoordinator()` for "close the whole sub-flow" cases.

---

## Compatibility notes

- Scaffolding requires Swift 6.2 (`@Observable`, the macro toolchain, strict concurrency). The package's `swift-tools-version` is `6.2`.
- Platform floor: iOS 18 / macOS 15 / tvOS 18 / watchOS 11 / macCatalyst 18. `TabRole` is available unconditionally on this floor.
- `onDismiss` and the deep-link trailing closures are typed `@MainActor () -> Void` / `@MainActor (T) -> Void`. Annotate any closures you forward.
- Scaffolding plays well with SwiftUI's `@Environment(\.dismiss)`, `@Environment(\.scenePhase)`, `@Environment(\.openURL)`, etc. — those are native environment values that don't conflict with the coordinator injection.
- Scaffolding **does** conflict with anything that introduces another `NavigationStack` (or `NavigationView`, `NavigationSplitView`) inside a flow's view tree.

---

## TL;DR for code generation

When asked to add navigation to a Scaffolding project:

1. **Don't generate `NavigationStack`, `NavigationView`, or `NavigationSplitView`** anywhere inside a `FlowCoordinatable`'s view hierarchy.
2. Decide push vs. modal vs. root-swap, then pick `route(to:)` / `present(_:as:)` / `setRoot(_:)`.
3. For modals, decide view-only vs. sub-flow:
   - View-only → SwiftUI native `.sheet(item:)`.
   - Sub-flow → `present(_:as:)` with a child coordinator.
4. New routes go on the coordinator as functions returning `some View`, `any Coordinatable`, or a tab tuple. Add the function — the macro generates the case.
5. Don't sprinkle `@ScaffoldingIgnored` on properties or `Void` helpers — the macro never tracks those. Use it only on functions whose return type *is* auto-tracked but that aren't destinations (`customize(_:)`, view-builder helpers, non-route factories).
6. Views read the coordinator from `@Environment(MyCoordinator.self)` and call methods on it. Views never store path or sheet booleans for flow-driven navigation.
7. Cross-coordinator results are delivered by the presenter installing an `onComplete` callback at construction time; the presented coordinator calls the callback then `dismissCoordinator()`.
8. Test navigation against the coordinator, not the UI: link **ScaffoldingTesting**, start from `Coordinator().activated()`, and assert with `depth` / `topDestination` / `isPresentingModal` / `isRoot(_:)` / `hierarchyContains(_:_:as:)`. Reach nested coordinators with `expecting:` in production code and `descendant(ofType:)` in tests.

If you can't figure out which coordinator should own a destination, the answer is usually "the closest existing one" — don't invent new coordinator types just to host one route.
