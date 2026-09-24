# Essentials

Learn the ownership model, the calls you use every day, and the rules every
Scaffolding app relies on.

## Overview

Coordinators own navigation state. Views read a coordinator from the
environment and call its methods. Scaffolding builds SwiftUI's native
containers — `NavigationStack`, `TabView`, `NavigationSplitView` — at
coordinator boundaries. The other guides assume this page.

## Choose a coordinator

![A root switches between Login and Main. Main owns independent tab flows; pushed children share a host stack and modal flows get a separate stack.](coordinator-ownership)

| Coordinator | Owns | Guide |
|---|---|---|
| ``FlowCoordinatable`` | A root screen and pushed screens | <doc:Flows> |
| ``RootCoordinatable`` | One active app branch | <doc:RootSwitching> |
| ``TabCoordinatable`` | Independent tabs | <doc:TabBars> |
| ``SplitCoordinatable`` | Sidebar, content, and detail columns | <doc:SplitViews> |

Every coordinator can also present sheets and covers; see
<doc:ModalsAndResults>. A feature exposes its coordinator and keeps its
screens internal; see <doc:ModularApps>.

## Declare routes in the class body

``Scaffoldable(injectsCoordinator:codable:)`` turns each class-body function
returning `some View` or `any Coordinatable` into a `Destinations` case.
Parameters become associated values.

- Return `any Coordinatable` for a child. `-> LoginCoordinator` is not a route.
- Functions in extensions are never routes. Put actions, deep links, and
  `customize(_:)` there.
- Keep factories free of side effects; navigate from actions.

See <doc:DefiningRoutes> for the exact rules.

## Mount the tree once

```swift
@main
struct MyApp: App {
    @State private var coordinator = AppCoordinator()

    var body: some Scene {
        WindowGroup { coordinator.view }
    }
}
```

`coordinator.view` renders the whole tree. A coordinator stored on the `App`
is shared by every window of its `WindowGroup`; create it in the window's
root view when each window needs independent navigation.

## Never nest navigation containers

Do not add `NavigationStack`, `NavigationView`, or `NavigationSplitView`
inside a route view or `customize(_:)`. Scaffolding places the stacks:

- A **pushed** child flow shares its host's stack.
- A **presented** child flow gets its own stack.
- Each tab and split column gets its own stack.
- A ``SplitCoordinatable`` may be a root destination, a tab, or a modal —
  never pushed, never a flow's root.

## Read coordinators from the environment

Every managed view receives its coordinator and all of its ancestors:

```swift
@Environment(HomeCoordinator.self) private var home  // the owner
@Environment(AppCoordinator.self) private var app    // any ancestor
```

- A missing non-optional lookup crashes — typically in an isolated preview.
  Use an optional lookup only when absence is valid for a reusable view.
- `@Scaffoldable(injectsCoordinator: false)` hides only that coordinator.
- Coordinators do not read `@Environment`. Pass dependencies to their
  initializers.

## Reach up the tree

How a coordinator reaches its host depends on your app's shape:

| App shape | Reach a host with | Guide |
|---|---|---|
| One module | ``Coordinatable/ancestor(ofType:)`` and ancestor environment lookups | <doc:MonolithicApps> |
| Feature packages | Results, injected capability protocols, and selection delegates | <doc:ModularApps> |

A feature in its own package cannot name the type that hosts it, so ancestor
lookups don't apply there.

## Use the destination value

Every managed view also receives `@Environment(\.destination)`, the
``Destination`` it renders:

| Member | Answers |
|---|---|
| ``Destination/dismiss()`` | Close this screen |
| ``Destination/dismiss(returning:)`` | Close it and return a value to the `awaiting:` caller |
| ``Destination/presentationType`` | How the screen appears: `.root`, `.push`, `.sheet`, `.fullScreenCover` |
| ``Destination/routeType`` | How it entered its own coordinator |
| ``Destination/meta`` | Which route case it is, without payload |
| ``Destination/column`` | Its split column, for a view route placed directly in one; otherwise `nil` |

What `dismiss()` removes depends on where the screen sits:

| Screen | Effect |
|---|---|
| Pushed | Removes it and everything above it |
| Presented | Closes that presentation |
| Root of a flow or root coordinator | Dismisses the enclosing coordinator |
| Top-level root, tab, or split column | Nothing — these are structural |
| Already removed | Nothing |

A flow root inside a sheet reads `routeType == .root` but
`presentationType == .sheet`. Use `presentationType` for Back/Close chrome:

```swift
struct CloseOrBack: View {
    @Environment(\.destination) private var destination

    var body: some View {
        switch destination.presentationType {
        case .push:
            Button("Back", systemImage: "chevron.left") { destination.dismiss() }
        case .sheet, .fullScreenCover:
            Button("Close") { destination.dismiss() }
        case .root:
            EmptyView()
        }
    }
}
```

Native `@Environment(\.dismiss)` keeps working and returns no value.

## Pick the call

| Intent | Call |
|---|---|
| Push a screen | `flow.route(to: .detail(id: 42))` |
| Go back one entry | `flow.pop()` |
| Go back to the flow root, clearing its modals | `flow.popToRoot()` |
| Present a sheet or cover | `coordinator.present(.settings)` |
| Close the visible modal, from the presenter | `coordinator.dismissPresentedModal()` |
| Finish a child flow, from inside | `child.dismissCoordinator()` |
| Close this screen, from its view | `destination.dismiss()` |
| Swap the app branch | `app.setRoot(.authenticated)` |
| Select a tab | `tabs.selectFirstTab(.home)` |
| Replace a split column | `split.setDetail(.item(id: 42))` |
| Show a view-only confirmation | Native `.alert` or `.sheet(item:)` |

- `pop()` removes the last stored entry, which may be a modal. On an empty
  stack it dismisses the coordinator. `pop(_:)` stops at the root.
- A top-level coordinator has no parent; `dismissCoordinator()` does nothing.
- Tab and column children cannot dismiss themselves. Remove the tab or
  replace the column.

## Get results and handles

`route(to:)` on flows and `present(_:)` on every coordinator accept the same
labels:

| Need | Add | Returns |
|---|---|---|
| Just navigate | — | `Self`, for chaining |
| The child now | `expecting: PickerCoordinator.self` | `PickerCoordinator?` |
| A result later | `awaiting: Item.self` + `await` | `Item?` |
| Dismissal only | `awaiting: Void.self` + `await` | `Void?` |
| Both | `expecting:` + `awaiting:` | `(coordinator, result)`; only `await result()` suspends |

- A swipe, a plain dismissal, or a type mismatch makes `awaiting:` return
  `nil`. Cancelling the waiting task returns `nil` and leaves the UI in place.
- `expecting:` returns `nil` for a view route or another type; the
  navigation still happens.
- Never store child references. Take them from `expecting:` when you
  navigate.

## Know the surprising semantics

- Navigation is synchronous on the main actor. Chain calls without `await`;
  SwiftUI renders on its next update.
- `policy: .distinct` compares cases only: `.detail(id: 1)` matches
  `.detail(id: 2)`. Guard record identity yourself.
- `setRoot` always builds a fresh branch, even for the same case. Modals owned
  by a root coordinator survive it; call `dismissAllModals()` to clear them.
- `setDetail`, `setContent`, and `setSidebar` replace their column; the old
  child loses its stack.
- Programmatic tab selection bypasses `shouldSelect(tab:isReselection:)`.
- Sheets and covers queue per host: the first shows, the rest wait. On macOS
  a full-screen cover renders as a sheet.

## Control animation

Each coordinator has `setTransitionAnimation(_:)`; `nil` disables its default
animation. To override animation for a whole chain, wrap it in a synchronous
scope:

```swift
withNavigationTransaction(animation: .disabled) {
    let tabs = app.setRoot(.main, expecting: MainTabCoordinator.self)
    tabs?.selectFirstTab(.home, expecting: HomeCoordinator.self)?
        .route(to: .detail(id: itemID))
}
```

| Policy | Effect |
|---|---|
| `.automatic` | Each coordinator's default |
| `.disabled` | No navigation or implicit SwiftUI animation |
| `.custom(.easeInOut)` | One animation for the scope |

Scopes nest and restore on return or throw. They do not carry into a new
`Task`. On `setRoot(_:animation:)`, `nil` inherits the default; wrap the swap
in a `.disabled` scope to suppress it.

## Keep local UI native

Use `.alert`, `.confirmationDialog`, and `.sheet(item:)` for view-only UI. Use
a route when the screen belongs to a flow, opens from code or a deep link, or
returns a result. Configure sheets on the presented content; see
<doc:ModalsAndResults#Configure-presented-content>.

## Preview a flow or a screen

```swift
#Preview("Flow") { HomeCoordinator().view }

#Preview("Screen") {
    DetailView(id: 42).environment(HomeCoordinator())
}
```

An isolated screen must be given every coordinator it reads, and its
`\.destination` is a default `.root` value. To preview a deeper state, add an
initializer that seeds `FlowStack(root:pushing:)`.

## See Also

- <doc:MeetScaffolding>
- <doc:Flows>
- <doc:ModalsAndResults>
