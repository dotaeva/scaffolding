# Meet Scaffolding

Learn how Scaffolding turns plain Swift functions into type-safe navigation
routes — and why you might never write a destination enum again.

## Overview

Navigation in SwiftUI is powerful, but as apps grow it creates a familiar set
of problems: navigation logic is scattered across views, destination enums
must be maintained by hand, and deep linking requires plumbing that touches
every layer of the app.

Scaffolding solves this by moving navigation into **coordinators** — observable
classes whose functions *are* the routes. The ``Scaffoldable()`` macro reads
those functions at compile time and generates a `Destinations` enum
automatically. You navigate by calling `route(to:)` with a generated case,
and Scaffolding handles the rest using SwiftUI's native navigation stack,
sheets, and full-screen covers under the hood.

### How It Works

1. Create a class and mark it `@Scaffoldable @Observable`.
2. Conform to one of three coordinator protocols.
3. Write functions — each one becomes a route.
4. The macro generates a `Destinations` enum from those functions.
5. Navigate by calling `coordinator.route(to: .someDestination)`.

### Return Types That Become Routes

The macro determines what kind of destination to generate based on the
function's return type:

| Return Type | What It Creates | Typical Use |
|---|---|---|
| `some View` | A view destination | Simple screens |
| `any Coordinatable` | A child coordinator | Nested navigation flows |
| `(any Coordinatable, some View)` | Coordinator + tab label | Tab bar tabs |
| `(some View, some View)` | View + tab label | View-only tabs |

Functions marked with ``ScaffoldingIgnored()`` or returning other types are
skipped.

## FlowCoordinatable — Navigation Stacks

``FlowCoordinatable`` manages a push/pop navigation stack with support for
sheet and full-screen-cover modals. This is the coordinator you will use most
often.

```swift
@Scaffoldable @Observable
final class HomeCoordinator: @MainActor FlowCoordinatable {
    var stack = FlowStack<HomeCoordinator>(root: .home)

    func home() -> some View { HomeView() }
    func detail(item: String) -> some View { DetailView(item: item) }
    func settings() -> any Coordinatable { SettingsCoordinator() }
}
```

Navigate with `route(to:as:)`:

```swift
coordinator.route(to: .detail(item: "Earth"))       // push
coordinator.route(to: .settings, as: .sheet)         // sheet
coordinator.route(to: .settings, as: .fullScreenCover) // full-screen cover
```

Go back with ``FlowCoordinatable/pop()``,
``FlowCoordinatable/popToRoot()``, or pop to a specific destination with
``FlowCoordinatable/popToFirst(_:)`` and ``FlowCoordinatable/popToLast(_:)``.

## TabCoordinatable — Tab Bars

``TabCoordinatable`` manages a tab bar where each tab can contain its own
coordinator with an independent navigation stack. Each function returns a
tuple of the tab's content and its label.

```swift
@Scaffoldable @Observable
final class MainTabCoordinator: @MainActor TabCoordinatable {
    var tabItems = TabItems<MainTabCoordinator>(tabs: [.feed, .profile])

    func feed() -> (any Coordinatable, some View) {
        (FeedCoordinator(), Label("Feed", systemImage: "list.bullet"))
    }

    func profile() -> (any Coordinatable, some View) {
        (ProfileCoordinator(), Label("Profile", systemImage: "person"))
    }
}
```

Select tabs programmatically, add or remove them at runtime:

```swift
coordinator.selectFirstTab(.feed)
coordinator.appendTab(.notifications)
coordinator.removeLastTab(.notifications)
```

On iOS 18+ you can also include a `TabRole` as a third tuple element to use
the new tab bar API.

## RootCoordinatable — State Switches

``RootCoordinatable`` holds a single root destination that can be swapped
atomically. This is ideal for authentication flows, onboarding gates, or any
state where the entire view hierarchy needs to change.

```swift
@Scaffoldable @Observable
final class AppCoordinator: @MainActor RootCoordinatable {
    var root = Root<AppCoordinator>(root: .splash)

    func splash() -> some View { SplashView() }
    func authenticated() -> any Coordinatable { MainTabCoordinator() }
    func unauthenticated() -> any Coordinatable { LoginCoordinator() }
}
```

One call flips the app state:

```swift
coordinator.setRoot(.authenticated)
```

## Environment Access

Scaffolding injects every coordinator in the hierarchy into the SwiftUI
environment. Views access their nearest coordinator with `@Environment`:

```swift
struct DetailView: View {
    @Environment(HomeCoordinator.self) private var coordinator

    var body: some View {
        Button("Next") {
            coordinator.route(to: .nextScreen)
        }
    }
}
```

If multiple coordinators of the same type exist in the view tree, the one
closest to the current view is used.

You can also inspect how the current view was presented by reading the
`destination` environment value:

```swift
@Environment(\.destination) private var destination

// destination.routeType        → .root, .push, .sheet, or .fullScreenCover
// destination.presentationType → how this view was presented globally
```

## Composing Coordinators

Coordinators nest naturally. A ``FlowCoordinatable`` can route to a child
coordinator (returned as `any Coordinatable`), which can itself be any
coordinator type. A typical app hierarchy might look like:

```
AppCoordinator (Root)
├── LoginCoordinator (Flow)
└── MainTabCoordinator (Tab)
    ├── HomeCoordinator (Flow)
    │   └── DetailCoordinator (Flow)
    └── ProfileCoordinator (Flow)
```

Navigate through multiple layers in a single call using the closure-based
API:

```swift
coordinator.route(to: .settings) { (settings: SettingsCoordinator) in
    settings.route(to: .account) { (account: AccountCoordinator) in
        account.setUser(currentUser)
    }
}
```

## Customizing Views

Override the `customize(_:)` function on a coordinator to apply shared
modifiers to every view it manages. Mark it with ``ScaffoldingIgnored()``
so the macro does not treat it as a route:

```swift
@ScaffoldingIgnored
func customize(_ view: AnyView) -> some View {
    view
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { /* shared toolbar items */ }
}
```

## Next Steps

Ready to try it yourself? Follow the
<doc:YourFirstScaffoldingProject> tutorial to build a working app in
under 25 minutes.
