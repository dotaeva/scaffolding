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

**Requirements:** iOS 18+ · macOS 15+ · tvOS 18+ · watchOS 11+ · macCatalyst 18+ · Swift 6.2 · Xcode 16+

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
| `route(to:onDismiss:)` | Push a destination onto the stack |
| `present(_:as:onDismiss:)` | Show a destination as a `.sheet` or `.fullScreenCover` |
| `pop()` / `popToRoot()` | Pop the topmost / everything-above-root |
| `popToFirst(_:)` / `popToLast(_:)` | Pop to a specific destination by `Meta` |
| `setRoot(_:animation:)` | Replace the root destination |
| `dismissCoordinator()` | Remove the whole coordinator from its parent |
| `isInStack(_:)` | Check whether a destination exists in the stack |

Each of these methods also exposes a `<T: Coordinatable>` overload with a trailing closure — handy for [deep linking](#advanced-usage).

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
| `present(_:as:onDismiss:)` | Show a destination as a `.sheet` or `.fullScreenCover` |

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

`RootCoordinatable` also exposes `present(_:as:onDismiss:)`, so a root coordinator can host a sheet or full-screen cover directly without delegating to a child flow.

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
signature.

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

## Macros Reference

| Macro | Target | Purpose |
|---|---|---|
| `@Scaffoldable(injectsCoordinator: Bool = true)` | Class | Generates `Destinations` enum from methods. Pass `injectsCoordinator: false` to opt this coordinator out of automatic environment injection. |
| `@ScaffoldingTracked` | Method | Explicit opt-in: once applied to any method on a coordinator, only methods carrying it become destinations. |
| `@ScaffoldingIgnored` | Method | Excludes a method from destination generation (e.g. a `customize(_:)` override). |

---

## Example Project

A full example using [Tuist](https://github.com/tuist/tuist) and The Modular Architecture is available [here](https://github.com/dotaeva/zen-example-tma).

---

<div align="center">

**MIT License**

</div>
