# Meet Scaffolding

Learn how Scaffolding turns plain Swift functions into type-safe navigation
routes — and why you might never write a destination enum again.

## Overview

Navigation in SwiftUI is powerful, but as apps grow it creates a familiar set
of problems: navigation logic is scattered across views, destination enums
must be maintained by hand, and deep linking requires plumbing that touches
every layer of the app.

Scaffolding solves this by moving navigation into **coordinators** — observable
classes whose functions *are* the routes. The ``Scaffoldable(injectsCoordinator:)`` macro reads
those functions at compile time and generates a `Destinations` enum
automatically. You navigate by calling `route(to:)` to push or
`present(_:as:)` to show a modal, and Scaffolding handles the rest using
SwiftUI's native navigation stack, sheets, and full-screen covers under the
hood.

### How It Works

1. Create a class and mark it `@Scaffoldable @Observable`.
2. Conform to one of three coordinator protocols.
3. Write functions — each one becomes a route.
4. The macro generates a `Destinations` enum from those functions.
5. Push with `coordinator.route(to: .someDestination)` or present a modal
   with `coordinator.present(.someDestination, as: .sheet)`.

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

## Mounting the Coordinator

A coordinator is a plain Swift class — it does not render anything until you
ask it to. Hold the root coordinator in SwiftUI `@State` at the app entry
point, then read its `view` property to mount its full navigation hierarchy
as a SwiftUI view:

```swift
@main
struct MyApp: App {
    @State private var coordinator = AppCoordinator()

    var body: some Scene {
        WindowGroup {
            coordinator.view              // computed property — no parens
        }
    }
}
```

`view` is a **computed property**, not a function. SwiftUI re-renders whenever
the coordinator's `@Observable` state changes, so the navigation stack,
presented modals, and injected child coordinators all stay in sync without
any further wiring.

The same property works in `#Preview` — instantiate the coordinator and read
`.view` directly:

```swift
#Preview {
    HomeCoordinator().view
}
```

Only the **root** coordinator needs an explicit `@State` mount. Child
coordinators returned from route functions (`any Coordinatable`) are
instantiated by the parent and rendered automatically when the parent routes
to them.

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

Push with `route(to:)`, present a modal with `present(_:as:)`:

```swift
coordinator.route(to: .detail(item: "Earth"))           // push
coordinator.present(.settings, as: .sheet)              // sheet
coordinator.present(.settings, as: .fullScreenCover)    // full-screen cover
```

`present(_:as:)` is available on every coordinator type, so a
``TabCoordinatable`` or ``RootCoordinatable`` can host a modal directly
without delegating to a child flow.

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
// destination.presentationType → effective presentation style
// destination.meta             → which generated case this destination is
```

A common use is a single reusable bar that adapts to context — back chevron
when pushed, **Close** when presented as a sheet, nothing when it is the
root:

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

Switch on `destination.meta` when the same view renders different layouts
depending on which generated case reached it. The `Meta` enum is emitted
alongside `Destinations` by the macro.

## Composing Coordinators

Coordinators nest naturally. A ``FlowCoordinatable`` can route to a child
coordinator (returned as `any Coordinatable`), which can itself be any
coordinator type. A typical app hierarchy might look like:

```
AppCoordinator (Root)
├── LoginCoordinator (Flow)              ← unauthenticated
└── MainTabCoordinator (Tab)             ← authenticated
    ├── HomeCoordinator (Flow)
    │   └── DetailView (push) + SettingsCoordinator (modal)
    └── ProfileCoordinator (Flow)
        └── EditProfileView (push)
```

When a presented coordinator needs to return a value to its parent, take an
`onComplete` callback at construction time. The presenter installs the
closure when it builds the child; the child invokes it when it has a result,
then dismisses itself:

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

## Deep Linking

Every navigation method that resolves a child coordinator
(``FlowCoordinatable/route(to:onDismiss:_:)``,
``FlowCoordinatable/present(_:as:onDismiss:_:)``,
``FlowCoordinatable/setRoot(_:animation:_:)``,
``RootCoordinatable/present(_:as:onDismiss:_:)``,
``RootCoordinatable/setRoot(_:animation:_:)``,
``TabCoordinatable/present(_:as:onDismiss:_:)``,
``TabCoordinatable/selectFirstTab(_:_:)``,
``TabCoordinatable/selectLastTab(_:_:)``,
``TabCoordinatable/appendTab(_:_:)``,
``TabCoordinatable/insertTab(_:at:_:)``,
``FlowCoordinatable/popToFirst(_:_:)``,
``FlowCoordinatable/popToLast(_:_:)``)
ships an overload constrained to `<T: Coordinatable>` with a trailing
closure. The closure fires after the route lands, receiving a typed
reference to the resolved child — chain them to walk the tree from a cold
launch:

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

The typed closure only fires if the resolved child can be cast to `T`. Pick
the concrete coordinator type that matches the route's return signature —
for `func authenticated() -> any Coordinatable { MainTabCoordinator() }`,
the closure parameter must be `MainTabCoordinator`.

## Dismissing a Flow

`pop()` and `dismissCoordinator()` are not the same call. `pop()` removes a
single pushed screen from the current flow's stack.
``Coordinatable/dismissCoordinator()`` removes the **entire coordinator**
from its parent — collapsing whatever sub-tree it owns (its root, every
screen it has pushed, every modal it has presented) in one move.

The difference shows up clearly in a nested flow. An `AppCoordinator`
presents a `LoginCoordinator` as a sheet; the login flow is itself two
screens (`email` → `password`). Calling `dismissCoordinator()` on the
password screen closes the whole sheet at once — not just the password
screen:

```swift
struct PasswordStepView: View {
    @Environment(LoginCoordinator.self) private var coordinator
    let email: String
    @State private var password = ""

    var body: some View {
        Form {
            SecureField("Password", text: $password)
            HStack {
                Button("Back")    { coordinator.pop() }                    // pop ONE screen
                Button("Sign in") {
                    let token = signIn(email: email, password: password)
                    coordinator.onComplete(token)
                    coordinator.dismissCoordinator()                       // close the whole sheet
                }
            }
        }
    }
}
```

For a single-screen back button inside a flow, prefer `pop()` or SwiftUI's
`@Environment(\.dismiss)`. Reach for `dismissCoordinator()` when the intent
is "I am done with this whole sub-flow," typically right after handing a
result back through an `onComplete` callback.

> Calling ``Coordinatable/dismissCoordinator()`` on the root coordinator is
a no-op — there is no parent to remove it from.

## Previewing Coordinator Code

SwiftUI's `#Preview` macro and Scaffolding's `@Scaffoldable` macro both run
at compile time, but they do not see each other the way the runtime does.
A handful of preview-only papercuts are easy to chase as bugs if you are
not expecting them:

- **The macro-generated routes cannot seed a custom initial state.** The
  `Destinations` enum is emitted as a member of the coordinator type, and
  the stack is constructed from a literal root case. There is no
  synthesised `init(initialRoute:)` — passing
  `HomeCoordinator(initialRoute: .detail)` does not compile. Preview the
  coordinator at its real root, or render the deeper screen directly.
- **Views that use `@Environment(SomeCoordinator.self)` need an explicit
  injection.** At runtime Scaffolding installs each coordinator into the
  environment of every view it manages. In `#Preview` you usually render a
  view by itself, outside the coordinator's view chain — so the
  environment is missing. Pass it yourself:
  `SomeScreen().environment(HomeCoordinator())`.
- **`\.destination` does not fully reflect runtime in previews.**
  Scaffolding sets the value when it materialises a destination through a
  route or modal presentation. A view rendered alone in `#Preview` is in no
  destination, so `destination.routeType`, `destination.presentationType`,
  and `destination.meta` read as `.root`. Avoid making rendering decisions
  that depend on those properties matching runtime; the `AdaptiveTopBar`
  pattern above is preview-safe because it falls through gracefully when
  the value is `.root`.

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
