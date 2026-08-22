# Migrating from Stinsen

Move a Stinsen codebase to Scaffolding — every Stinsen concept, its
Scaffolding equivalent, and the cases with no direct counterpart.

## Overview

[Stinsen](https://github.com/rundfunk47/stinsen) popularized the coordinator
pattern in SwiftUI, and Scaffolding deliberately keeps its architecture:
coordinators are plain observable classes that own navigation state, views
ask their coordinator to navigate, and child coordinators compose into a
tree. If your app follows Stinsen's discipline, the migration is largely
mechanical — this guide maps every construct.

The fundamentals that changed underneath:

- **Route declarations.** Stinsen declares each route twice — a
  property-wrapped key path (`@Route(.push) var todo = makeTodo`) plus the
  factory it points to. In Scaffolding the factory function *is* the route:
  the ``Scaffoldable(injectsCoordinator:codable:)`` macro reads your
  functions and generates a `Destinations` enum. Key paths (`\.todo`)
  become enum cases (`.todo`).
- **Rendering.** Stinsen re-implements stack behavior over
  `NavigationView` and `isActive` bindings. Scaffolding renders through
  SwiftUI's native `NavigationStack`, sheets, and full-screen covers.
- **Observation.** Stinsen is built on `ObservableObject` and Combine.
  Scaffolding coordinators are `@Observable` and `@MainActor`, and build
  under Swift 6 strict concurrency.
- **Push vs. modal.** Stinsen keeps pushes and modals in one stack and
  `popLast()` removes either. Scaffolding separates them: `route(to:)`
  always pushes, `present(_:as:)` always presents, `pop()` pops, and
  `dismissModal()` dismisses.

> Important: Scaffolding requires Swift 6.2 and iOS 18 / macOS 15 /
> tvOS 18 / watchOS 11 as the platform floor — a significant jump from
> Stinsen's iOS 13. Confirm your deployment target before starting.
>
> Both packages can be linked during an incremental migration, but they
> collide on the names `Coordinatable`, `PresentationType`, and (with
> SwiftUI) `NavigationStack` — qualify with the module name
> (`Scaffolding.Coordinatable` vs. `Stinsen.Coordinatable`) in files that
> import both.

![A root coordinator swapping between a login flow and a tab coordinator that owns two flows.](diagram-tree)

## Concept Map

| Stinsen | Scaffolding |
|---|---|
| `NavigationCoordinatable` | ``FlowCoordinatable`` |
| `TabCoordinatable` | ``TabCoordinatable`` |
| Multiple `@Root`s + `root(\.x)` | ``RootCoordinatable`` + `setRoot(_:)` |
| `NavigationViewCoordinator` | Not needed — a flow coordinator *is* the navigation stack |
| `ViewWrapperCoordinator` | `customize(_:)` on any coordinator |
| `NavigationStack(initial:)` (Stinsen's own type) | ``FlowStack`` |
| `TabChild(startingItems:activeTab:)` | ``TabItems`` |
| `@Root` / `@Route` property wrappers | Plain functions; the macro generates the routes |
| `MyCoordinator.Router` via `@EnvironmentObject` | `@Environment(MyCoordinator.self)` |
| `RouterStore` / `@RouterObject` | No global store — inject the coordinator, or use `ancestor(ofType:)` |
| `.view()` | `.view` (computed property, no parentheses) |

## Flow Coordinators

A Stinsen `NavigationCoordinatable` and its Scaffolding equivalent,
side by side. Stinsen first:

```swift
import Stinsen

final class UnauthenticatedCoordinator: NavigationCoordinatable {
    let stack = NavigationStack(initial: \UnauthenticatedCoordinator.start)

    @Root var start = makeStart
    @Route(.push) var registration = makeRegistration
    @Route(.modal) var forgotPassword = makeForgotPassword

    func makeRegistration() -> RegistrationCoordinator {
        RegistrationCoordinator()
    }

    @ViewBuilder func makeForgotPassword() -> some View {
        ForgotPasswordScreen()
    }

    @ViewBuilder func makeStart() -> some View {
        LoginScreen()
    }
}
```

The same coordinator in Scaffolding:

```swift
import Scaffolding

@MainActor @Observable @Scaffoldable
final class UnauthenticatedCoordinator: @MainActor FlowCoordinatable {
    var stack = FlowStack<UnauthenticatedCoordinator>(root: .start)

    func start() -> some View { LoginScreen() }
    func registration() -> any Coordinatable { RegistrationCoordinator() }
    func forgotPassword() -> some View { ForgotPasswordScreen() }
}
```

Rules for the conversion:

- Drop the `make` prefix — the function name becomes the case name
  (`func registration()` generates `.registration`).
- The `@Root` route becomes the ``FlowStack`` root case:
  `FlowStack<Self>(root: .start)`. `stack` is `var`, not `let`.
- No `@ViewBuilder` needed on route functions.
- Factories returning a **concrete** coordinator
  (`-> RegistrationCoordinator`) must return the existential
  `-> any Coordinatable` instead — the macro only tracks that spelling.
- The transition (`.push` / `.modal`) is **not** declared on the route
  anymore. It moves to the call site: `route(to:)` to push,
  `present(_:as:)` for modals. The same destination can be pushed from
  one place and presented from another.
- Route arguments stay function parameters, and their labels become
  associated-value labels: `func todo(id: Todo.ID) -> some View`
  is routed as `.todo(id:)`.

### Delete Your NavigationViewCoordinators

Stinsen requires wrapping a `NavigationCoordinatable` in a
`NavigationViewCoordinator` to get an actual `NavigationView`:

```swift
// Stinsen
func makeTodos() -> NavigationViewCoordinator<TodosCoordinator> {
    NavigationViewCoordinator(TodosCoordinator())
}
```

In Scaffolding every ``FlowCoordinatable`` owns its `NavigationStack`.
Unwrap them:

```swift
// Scaffolding
func todos() -> any Coordinatable { TodosCoordinator() }
```

And never reintroduce the wrapper by hand — putting a `NavigationStack`
(or `NavigationView`) inside a route function's view breaks routing.
The coordinator boundary is where the stack lives.

## Root Switching

Stinsen folds root switching into `NavigationCoordinatable`: declare
several `@Root`s and swap with `root(\.x)`:

```swift
// Stinsen
final class MainCoordinator: NavigationCoordinatable {
    let stack = NavigationStack(initial: \MainCoordinator.unauthenticated)

    @Root var unauthenticated = makeUnauthenticated
    @Root var authenticated = makeAuthenticated

    func signIn() { root(\.authenticated) }
    func signOut() { root(\.unauthenticated) }
}
```

Scaffolding gives this job its own protocol, ``RootCoordinatable``:

```swift
// Scaffolding
@MainActor @Observable @Scaffoldable
final class MainCoordinator: @MainActor RootCoordinatable {
    var root = Root<MainCoordinator>(root: .unauthenticated)

    func unauthenticated() -> any Coordinatable { UnauthenticatedCoordinator() }
    func authenticated()   -> any Coordinatable { AuthenticatedCoordinator() }

    func signIn()  { setRoot(.authenticated) }
    func signOut() { setRoot(.unauthenticated) }
}
```

The method-by-method mapping:

| Stinsen | Scaffolding |
|---|---|
| `root(\.x)` | `setRoot(.x)` — with an optional `animation:` parameter |
| `root(\.x, input)` | `setRoot(.x(input:))` |
| `isRoot(\.x)` | `isRoot(.x)` |
| `hasRoot(\.x)` (returns the active child) | `setRoot(.x, expecting: ChildType.self)` — returns the typed child; gate with `isRoot(.x)` when you must not switch |

If a coordinator mixed pushed routes and multiple roots, split it: a
``RootCoordinatable`` at the top whose destinations are the flow
coordinators that previously lived behind each `@Root`. See
<doc:AuthenticationFlow> for the full pattern.

## Views: Routers Become Environment Coordinators

Stinsen views fetch a generated `Router` with `@EnvironmentObject`:

```swift
// Stinsen
struct TodosScreen: View {
    @EnvironmentObject var router: TodosCoordinator.Router

    var body: some View {
        List { /* … */ }
            .toolbar {
                Button("Add") { router.route(to: \.createTodo) }
            }
    }
}
```

Scaffolding injects the coordinator itself — and every ancestor
coordinator — into the environment:

```swift
// Scaffolding
struct TodosScreen: View {
    @Environment(TodosCoordinator.self) private var coordinator

    var body: some View {
        List { /* … */ }
            .toolbar {
                Button("Add") { coordinator.route(to: .createTodo) }
            }
    }
}
```

There is no separate router type. Where a Stinsen view reached a
*higher* router (e.g. the tab coordinator's, to switch tabs), read the
ancestor directly: `@Environment(AuthenticatedCoordinator.self)` works
from any depth below it.

### RouterStore and View Models

Stinsen's `RouterStore.shared.retrieve()` and `@RouterObject` exist
because `@EnvironmentObject` is view-only. Scaffolding has no global
store — and doesn't need one:

- **Pass the coordinator in** when constructing the view model, exactly
  as Stinsen's own documentation recommends as the "maximum control"
  option. Coordinators are plain classes; hold them weakly in the view
  model if it outlives the flow.
- **From a coordinator, reach upward** with
  `ancestor(ofType: MainCoordinator.self)` instead of retrieving an
  unrelated router from a global registry.

Migrate every `@RouterObject` to one of those two forms — global lookup
has no equivalent by design.

## Navigation Calls

| Stinsen | Scaffolding |
|---|---|
| `route(to: \.details)` (a `.push` route) | `route(to: .details)` |
| `route(to: \.details, todo.id)` | `route(to: .details(id: todo.id))` |
| `route(to: \.settings)` (a `.modal` route) | `present(.settings, as: .sheet)` |
| `route(to: \.player)` (a `.fullScreen` route) | `present(.player, as: .fullScreenCover)` |
| `@Route(.modal(dismissible: false))` / `.modalNonDismissible` | `present(.x, as: .sheet(interactiveDismissDisabled: true))` |
| `route(..., onDismiss:)` | Prefer `await routeAndWait(to:)` / `await presentAndWait(_:as:)` and continue after the `await`; `onDismiss:` closures remain for fire-and-forget cases |
| `popLast()` | `pop()` for a pushed screen; `dismissModal()` for a modal |
| `pop()` (router-only, pops *that* view) | `pop()` on the coordinator, or SwiftUI's `@Environment(\.dismiss)` — both work |
| `popToRoot()` | `popToRoot()` |
| `focusFirst(\.todo)` | `popToFirst(.todo)` |
| `dismissCoordinator()` | `dismissCoordinator()` |
| `dismissChild(coordinator:action:)` | `dismissModal()` on the presenter (fires the modal's `onDismiss`) |

Two behavioral differences to internalize, because they change call
sites rather than just spellings:

- **Stinsen's unified stack is gone.** `popLast()` removed whatever was
  last — push or modal. In Scaffolding, `pop()` operates on pushed
  destinations and `dismissModal()` on presented ones; `dismissModal()`
  is a safe no-op when nothing is presented. Audit every `popLast()`
  call and pick the right verb.
- **One modal at a time.** Stinsen allowed stacking modals in its
  navigation stack. A Scaffolding coordinator presents a single modal;
  a flow presented *inside* that modal presents its own. If you relied
  on modal-on-modal from one coordinator, restructure the inner modal
  into the presented coordinator (see <doc:ModalSubFlows>).

Also note what `pop()` does at the root: on an empty stack it dismisses
the whole coordinator. For closing modals, prefer `dismissModal()` —
it never touches pushed destinations.

### One-Screen Modals Can Go Native

Stinsen routed every modal, even a single confirmation sheet. In
Scaffolding, a modal that is one self-contained screen should use
SwiftUI's `.sheet(item:)` directly in the view — reserve
`present(_:as:)` for modals that contain their own flow. Migrating is a
good moment to demote those routes; it shrinks the coordinator's
surface.

## Tab Coordinators

Stinsen declares tabs with `TabChild` and `@Route(tabItem:)`:

```swift
// Stinsen
final class AuthenticatedCoordinator: TabCoordinatable {
    var child = TabChild(startingItems: [
        \AuthenticatedCoordinator.home,
        \AuthenticatedCoordinator.todos,
        \AuthenticatedCoordinator.profile
    ])

    @Route(tabItem: makeHomeTab) var home = makeHome
    @Route(tabItem: makeTodosTab) var todos = makeTodos
    @Route(tabItem: makeProfileTab, onTapped: onProfileTapped) var profile = makeProfile

    func makeHome() -> NavigationViewCoordinator<HomeCoordinator> {
        NavigationViewCoordinator(HomeCoordinator())
    }

    @ViewBuilder func makeHomeTab(isActive: Bool) -> some View {
        Image(systemName: isActive ? "house.fill" : "house")
        Text("Home")
    }

    func onProfileTapped(_ isRepeat: Bool, coordinator: ProfileCoordinator) {
        /* … */
    }
    /* … */
}
```

The Scaffolding version — each tab is one function returning a
`(coordinator, label)` tuple:

```swift
// Scaffolding
@MainActor @Observable @Scaffoldable
final class AuthenticatedCoordinator: @MainActor TabCoordinatable {
    var tabItems = TabItems<AuthenticatedCoordinator>(tabs: [.home, .todos, .profile])

    func home() -> (any Coordinatable, some View) {
        (HomeCoordinator(), Label("Home", systemImage: "house"))
    }
    func todos() -> (any Coordinatable, some View) {
        (TodosCoordinator(), Label("Todos", systemImage: "checklist"))
    }
    func profile() -> (any Coordinatable, some View) {
        (ProfileCoordinator(), Label("Profile", systemImage: "person"))
    }

    // Returns Bool ⇒ never tracked by the macro.
    func shouldSelect(tab: Destinations.Meta, isReselection: Bool) -> Bool {
        if isReselection && tab == .profile { /* … */ }
        return true
    }
}
```

| Stinsen | Scaffolding |
|---|---|
| `TabChild(startingItems: [\.home, …])` | `TabItems(tabs: [.home, …])` |
| `TabChild(…, activeTab: 1)` | `select(index: 1)` after creation, or reorder `tabs` |
| `@Route(tabItem: makeXTab) var x = makeX` | One function returning `(any Coordinatable, some View)` — or `(some View, some View)` for a view-only tab |
| `makeXTab(isActive: Bool)` — active-state styling | No `isActive` parameter; the system styles the selected tab. For fully custom selection UI, hide the bar and build your own (see <doc:TabsAndFlows>) |
| `onTapped(isRepeat, output)` | `shouldSelect(tab:isReselection:)` — return `false` to veto a UI-driven switch; `isReselection == true` on re-tap |
| `focusFirst(\.todos)` | `selectFirstTab(.todos)` |
| `child.activeTab = 2` | `select(index: 2)` |

Three upgrades come for free once you're on ``TabItems``: badges
(`setBadge("3", for: .todos)`), per-tab accessibility identifiers
(`setTabAccessibilityIdentifier("tab.todos", for: .todos)`, which reaches
the rendered tab bar item where a modifier on the label view does not), and
tab-bar visibility control — none of which Stinsen's `TabChild` tracked. Note that programmatic selection
(`selectFirstTab`, `select(index:)`) bypasses `shouldSelect` — the hook
only intercepts taps on the tab bar, where Stinsen's `onTapped` fired
for taps as well.

## Chaining and Deep Linking

Stinsen chains routing calls through their return values:

```swift
// Stinsen
authenticatedRouter
    .focusFirst(\.todos)
    .child
    .popToRoot()
    .route(to: \.todo, todo.id)
```

Scaffolding routes land synchronously, so the chain becomes
straight-line code: every resolving method (`route`, `present`,
`setRoot`, `selectFirstTab`, `popToFirst`, …) has an `expecting:`
overload that returns the typed child immediately —

```swift
// Scaffolding
guard let todos = authenticated.selectFirstTab(.todos, expecting: TodosCoordinator.self) else { return }
todos.popToRoot()
todos.route(to: .todo(id: todo.id))
```

The `.child` hop disappears along with `NavigationViewCoordinator`, and
no `await` is needed — navigation state mutates synchronously; async
enters only when you *wait for a dismissal* (`presentAndWait`,
`present(_:awaiting:)`). From a cold launch:

```swift
// Scaffolding — full deep link from a URL
func openTodo(id: Todo.ID) {
    guard
        let tabs = setRoot(.authenticated, expecting: AuthenticatedCoordinator.self),
        let todos = tabs.selectFirstTab(.todos, expecting: TodosCoordinator.self)
    else { return }

    todos.route(to: .todo(id: id))
}
```

Each `expecting:` call returns `nil` when the destination is view-only
or resolves to a different coordinator type, so a mistyped chain fails
safely instead of routing somewhere wrong. (A trailing-closure form
also exists — `selectFirstTab(.todos) { (todos: TodosCoordinator) in … }` —
if you prefer the nested style.)

Stinsen's README hangs `onOpenURL` inside `customize(_:)`; in
Scaffolding attach it at the app entry point and call one coordinator
method:

```swift
WindowGroup {
    coordinator.view
        .onOpenURL { url in
            if let id = parseTodoURL(url) { coordinator.openTodo(id: id) }
        }
}
```

See <doc:DeepLinking> for guarded links and notification-driven routing.

## Customize and ViewWrapperCoordinator

`customize(_:)` survives with the same name and shape — but because it
returns `some View`, the macro would treat it as a route. Mark it
``ScaffoldingIgnored()``:

```swift
// Scaffolding
@ScaffoldingIgnored
func customize(_ view: AnyView) -> some View {
    view.onAppear { /* … */ }
}
```

A Stinsen `ViewWrapperCoordinator` (or a subclass of it) usually exists
only to wrap a child in chrome. Fold it into the parent's
`customize(_:)`, or into the child coordinator's own `customize(_:)`,
and delete the wrapper. The reactive root-switching some apps put in
`customize` (Stinsen's README subscribes to an auth publisher there)
belongs on the ``RootCoordinatable`` itself — observe the service in
the coordinator and call `setRoot(_:)`.

## Dismissal Callbacks and Results

Stinsen scatters completion hooks across call sites: `popLast(action)`,
`popToRoot(action)`, `dismissCoordinator(action)`, and per-route
`onDismiss:` parameters. When migrating this plumbing, **prefer the
async forms** — suspend until the destination leaves and continue in
straight-line code instead of installing a closure:

```swift
// Stinsen
route(to: \.editor, onDismiss: { [weak self] in self?.reload() })

// Scaffolding — preferred
await presentAndWait(.editor, as: .sheet)
reload()
```

`routeAndWait(to:)` is the pushed-destination equivalent, and both
resume exactly once no matter how the destination leaves — pop, swipe,
or programmatic dismissal. When a presented flow should hand a value
back, await it directly:

```swift
// Scaffolding — resumes with nil if the picker is swiped away
let amount = await present(.limitPicker, awaiting: Decimal.self)
```

The child delivers the result with `dismissCoordinator(returning:)`;
any other dismissal resumes with `nil`, so cancellation is handled for
free. Neither form has a Stinsen counterpart, and migrating
delegate-style plumbing to them usually deletes code.

Reserve the closure forms for the two cases async doesn't fit: a
constructor callback when the child must report *before* dismissing
(the presenter passes a closure in; the child calls it, then
`dismissCoordinator()`), and `onDismiss:` when the caller genuinely
fires-and-forgets.

## No Equivalent in Stinsen

New capabilities you get after migrating — worth adopting rather than
porting workarounds:

- **Route policies.** `route(to: .detail(item:), policy: .distinct)`
  swallows double-taps that would push the same case twice.
- **Presenter-side sheet configuration.**
  `present(.settings, as: .sheet(detents: [.medium, .large]))`.
- **Orientation.** `routeType`, `depth`, `topDestination`,
  `isInStack(_:)`, `isPresentingModal`, and
  `hierarchyRoot.debugHierarchy()` — print the live coordinator tree
  when routing misbehaves.
- **State restoration.** `@Scaffoldable(codable: true)` +
  `captureNavigationState()` / `restoreNavigationState(from:)` — see
  <doc:StateRestoration>.
- **Unit-testable navigation.** Every navigation call mutates state
  synchronously; the `ScaffoldingTesting` library adds `activated()`,
  `descendant(ofType:)`, `hierarchyContains`, and `waitUntil` — see
  <doc:TestingCoordinators>. Stinsen's MVVM-C example tested view
  models; here you test the shipping coordinators themselves.

## Migration Checklist

1. Raise the deployment target (iOS 18 / macOS 15) and toolchain
   (Swift 6.2), and add the Scaffolding package.
2. Pick one leaf flow (no child coordinators) and convert it:
   - Replace `NavigationCoordinatable` with
     `@MainActor @Observable @Scaffoldable` +
     `@MainActor FlowCoordinatable`.
   - Collapse each `@Route`/factory pair into one function; drop
     `make` prefixes and `@ViewBuilder`; return `any Coordinatable`
     for child-coordinator routes.
   - Replace `stack = NavigationStack(initial:)` with
     `stack = FlowStack<Self>(root:)`.
3. In that flow's views, swap
   `@EnvironmentObject var router: X.Router` for
   `@Environment(X.self)`, and update calls: key paths → enum cases,
   modal routes → `present(_:as:)`, `popLast()` → `pop()` or
   `dismissModal()`. Replace completion-closure plumbing
   (`onDismiss:`, `popLast(action)`, `dismissCoordinator(action)`) with
   `await routeAndWait` / `presentAndWait` / `present(_:awaiting:)`
   wherever the caller continues after dismissal.
4. Unwrap every `NavigationViewCoordinator` around the converted flow.
5. Work upward: tab coordinators (`TabChild` → ``TabItems``, tab routes
   → tuple functions, `onTapped` → `shouldSelect`), then the root
   (multiple `@Root`s → a ``RootCoordinatable``).
6. Replace `RouterStore` / `@RouterObject` in view models with injected
   coordinators or `ancestor(ofType:)`.
7. Convert chained deep links to typed trailing closures, and move
   `onOpenURL` from `customize` to the app entry point.
8. Mark surviving `customize(_:)` implementations
   ``ScaffoldingIgnored()``.
9. Delete the Stinsen dependency, then add coordinator unit tests —
   <doc:TestingCoordinators> — for the flows you just touched.

## See Also

- <doc:MeetScaffolding>
- <doc:YourFirstScaffoldingProject>
- <doc:TabsAndFlows>
- <doc:AuthenticationFlow>
- <doc:DeepLinking>
