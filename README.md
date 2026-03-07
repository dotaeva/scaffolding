<div align="center">

# Scaffolding 目

**Macro-powered SwiftUI navigation that stays out of your way.**

[![Swift 5.9+](https://img.shields.io/badge/Swift-5.9+-F05138.svg?style=flat&logo=swift)](https://swift.org)
[![iOS 17+](https://img.shields.io/badge/iOS-17%2B-007AFF.svg?style=flat&logo=apple)](https://developer.apple.com/ios/)
[![macOS 14+](https://img.shields.io/badge/macOS-14%2B-000000.svg?style=flat&logo=apple)](https://developer.apple.com/macos/)
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
coordinator.route(to: .detail(item: selectedItem))
coordinator.route(to: .settings, as: .sheet)
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

---

## Installation

Add Scaffolding via Swift Package Manager:

```
https://github.com/dotaeva/scaffolding.git
```

**Requirements:** iOS 17+ / macOS 14+ · Swift 5.9+ · Xcode 15+

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
| `route(to:as:)` | Navigate to a destination (push, sheet, or fullScreenCover) |
| `pop()` | Pop the current view |
| `popToRoot()` | Return to the root |
| `popToFirst(_:)` / `popToLast(_:)` | Pop to a specific destination |
| `setRoot(_:)` | Replace the root destination |
| `isInStack(_:)` | Check if a destination exists in the stack |

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

> `TabRole` support requires iOS 18+.

**API:**

| Method | Description |
|---|---|
| `selectFirstTab(_:)` / `selectLastTab(_:)` | Select a tab by destination |
| `select(index:)` / `select(id:)` | Select by index or ID |
| `appendTab(_:)` / `insertTab(_:at:)` | Add tabs dynamically |
| `removeFirstTab(_:)` / `removeLastTab(_:)` | Remove tabs |
| `setTabs(_:)` | Replace all tabs |

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

---

## Full Example

```swift
@main
struct MyApp: App {
    @State private var appCoordinator = AppCoordinator()

    var body: some Scene {
        WindowGroup {
            appCoordinator.view()
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

### Nested Routing

Navigate through multiple coordinator layers in a single call:

```swift
coordinator.route(to: .settings) { (settings: SettingsCoordinator) in
    settings.route(to: .accountDetails) { (account: AccountCoordinator) in
        account.setUser(currentUser)
    }
}
```

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

// destination.routeType       → .root, .push, .sheet, or .fullScreenCover
// destination.presentationType → how this view was presented globally
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
| `@Scaffoldable` | Class | Generates `Destinations` enum from methods |
| `@ScaffoldingIgnored` | Method | Excludes a method from destination generation |

---

## Example Project

A full example using [Tuist](https://github.com/tuist/tuist) and The Modular Architecture is available [here](https://github.com/dotaeva/zen-example-tma).

---

<div align="center">

**MIT License**

</div>
