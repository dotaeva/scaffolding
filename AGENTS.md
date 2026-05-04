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
| Atomically replace the entire view hierarchy (auth, onboarding) | `appCoordinator.setRoot(.authenticated)` (on a `RootCoordinatable`) |
| Switch tabs programmatically | `tabCoordinator.selectFirstTab(.home)` |

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

    // Optional helpers (regular methods, not auto-generated).
    func openDetail(_ item: Item) {
        route(to: .detail(item: item))
    }
}
```

### Auto-tracked return types

The `@Scaffoldable` macro generates a `Destinations` enum with one case per function whose return type is one of:

| Return type | What it generates |
|---|---|
| `some View` | A view destination |
| `any Coordinatable` | A child-coordinator destination |
| `(any Coordinatable, some View)` | Tab tuple (coordinator + label) |
| `(some View, some View)` | Tab tuple (view-only + label) |
| `(any Coordinatable, some View, TabRole)` | Tab tuple with role |
| `(some View, some View, TabRole)` | Tab tuple with role + view-only |

Anything else — including a **concrete** coordinator type like `-> LoginCoordinator` — is **not** recognised. For a child coordinator the return type **must** be `any Coordinatable` (the existential).

```swift
// ❌ Won't be picked up — concrete type.
func login() -> LoginCoordinator { LoginCoordinator() }

// ✅ Existential — macro generates a `.login` case.
func login() -> any Coordinatable { LoginCoordinator() }
```

### Marking exclusions

Use `@ScaffoldingIgnored` whenever a method returns one of the auto-tracked types but **isn't** a destination — typically a `customize(_:)` override or a helper view builder shared between screens:

```swift
@ScaffoldingIgnored
func customize(_ view: AnyView) -> some View {
    view
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { /* shared toolbar */ }
}
```

Use `@ScaffoldingTracked` only when you want the *opposite* default — explicit opt-in. After applying it once, only methods carrying `@ScaffoldingTracked` are emitted as destinations.

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

### 2. Concrete coordinator return types

```swift
// ❌ Macro skips this — it doesn't recognise concrete types as routes.
func login() -> LoginCoordinator { LoginCoordinator() }
```

Use `any Coordinatable`.

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
5. Views read the coordinator from `@Environment(MyCoordinator.self)` and call methods on it. Views never store path or sheet booleans for flow-driven navigation.
6. Cross-coordinator results are delivered by the presenter installing an `onComplete` callback at construction time; the presented coordinator calls the callback then `dismissCoordinator()`.

If you can't figure out which coordinator should own a destination, the answer is usually "the closest existing one" — don't invent new coordinator types just to host one route.
