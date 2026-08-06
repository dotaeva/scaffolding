# The `@Scaffoldable` macro

`@Scaffoldable` is a member macro applied to a **class** that conforms to `FlowCoordinatable`, `TabCoordinatable`, or `RootCoordinatable`. It scans the class's **functions** — and only functions; stored/computed properties, `init`, and `deinit` are never scanned — and generates:

- a `Destinations` enum with one case per tracked function (associated values mirror the function's parameters),
- a nested `Destinations.Meta` enum (case names without associated values, conforming to `DestinationMeta`) used by `popToFirst/Last`, `selectFirstTab`, `isInStack`, `shouldSelect`, etc.,
- a `value(for:)` bridge the framework uses to resolve cases into live `Destination` values.

```swift
@MainActor @Observable @Scaffoldable
final class HomeCoordinator: @MainActor FlowCoordinatable {
    var stack = FlowStack<HomeCoordinator>(root: .home)

    func home() -> some View { HomeView() }
    func detail(item: Item) -> some View { DetailView(item: item) }
}

// Generated (conceptually):
// enum Destinations { case home; case detail(item: Item); enum Meta { case home, detail } }
coordinator.route(to: .detail(item: planet))
```

Declaration order of the attributes doesn't matter, but the class must be a `class` (typically `final`), `@Observable`, and conform to exactly one of the three coordinator protocols.

The conformance may be spelled through a **refining protocol** — useful for sharing `customize(_:)` across several flows. The macro reads syntax only, so when the inheritance clause names no coordinator protocol directly it infers the kind from the declared state container (`FlowStack` / `TabItems` / `Root`), in either spelling:

```swift
@MainActor protocol TabFlow: FlowCoordinatable { }
extension TabFlow {
    func customize(_ view: AnyView) -> some View { view.padding(.bottom, 60) }
}

@MainActor @Observable @Scaffoldable
final class HomeCoordinator: @MainActor TabFlow {
    var stack = FlowStack<HomeCoordinator>(root: .home)   // ⇒ flow coordinator
    func home() -> some View { HomeView() }
}
```

A `customize(_:)` supplied by such a protocol extension needs no `@ScaffoldingIgnored` — the macro only scans functions declared in the class body.

## Auto-tracked return types

A function becomes a `Destinations` case **iff** its return type is one of:

| Return type | Generates |
|---|---|
| `some View` | View destination |
| `any Coordinatable` | Child-coordinator destination |
| `(any Coordinatable, some View)` | Tab: coordinator + label view |
| `(some View, some View)` | Tab: content view + label view |
| `(any Coordinatable, TabRole)` | Tab: coordinator + role |
| `(some View, TabRole)` | Tab: view + role |
| `(any Coordinatable, some View, TabRole)` | Tab: coordinator + label + role |
| `(some View, some View, TabRole)` | Tab: view + label + role |

Everything else is skipped automatically: `Void` functions, `Bool`/`Int`/other concrete returns, **concrete coordinator types** (`-> LoginCoordinator`), closures, generics (`Foo<Bar>`), arrays, and unlisted tuple shapes.

```swift
// ❌ Not tracked — concrete type. No case is generated.
func login() -> LoginCoordinator { LoginCoordinator() }

// ✅ Tracked — must return the existential.
func login() -> any Coordinatable { LoginCoordinator() }
```

Tuple shapes and `TabRole` are only meaningful on a `TabCoordinatable`; using them on a flow/root coordinator emits a compiler **warning** (the extra tuple members are ignored).

## Parameters become case payloads

Labels, internal names, and **default values** are preserved; `_` labels stay unlabeled; `@escaping`/`@autoclosure` are stripped from the payload type:

```swift
func detail(item: Item, editable: Bool = false) -> some View { ... }
func login(onComplete: @escaping @MainActor (AuthToken) -> Void) -> any Coordinatable {
    LoginCoordinator(onComplete: onComplete)
}

// route(to: .detail(item: x))                    // default applies
// present(.login(onComplete: { token in ... }))  // closures ride along as payload
```

Closure parameters are the idiomatic channel for delivering results back from a presented child coordinator (see `scaffolding-routing` → `dismissal-and-results.md`).

## `@ScaffoldingIgnored` — needed rarely, and only on functions

Use it **only** when a function's return type is in the table above but the function isn't a destination:

```swift
// ✅ Genuinely needed — returns `some View` but is chrome, not a route.
@ScaffoldingIgnored
func customize(_ view: AnyView) -> some View {
    view.toolbar { /* shared toolbar */ }
}

// ✅ Shared view-builder helper.
@ScaffoldingIgnored
func emptyState(message: String) -> some View { ... }

// ✅ Factory returning a coordinator that is never routed to directly.
@ScaffoldingIgnored
func makeDebugCoordinator() -> any Coordinatable { ... }
```

**Do not** sprinkle it on non-tracked members — that is redundant noise and should be removed in review:

```swift
// ❌ All redundant — none of these is ever scanned/tracked.
@ScaffoldingIgnored var session: AuthToken?                    // property
@ScaffoldingIgnored func openDetail(_ item: Item) { ... }      // returns Void
@ScaffoldingIgnored func makeHandler() -> () -> Void { ... }   // closure return
@ScaffoldingIgnored func shouldSelect(tab: Destinations.Meta,
                                      isReselection: Bool) -> Bool { ... } // returns Bool
```

There is no opt-in attribute. Auto-tracking by return type plus `@ScaffoldingIgnored` exclusion is the whole mechanism.

## Macro arguments

```swift
@Scaffoldable(injectsCoordinator: Bool = true, codable: Bool = false)
```

- `injectsCoordinator: false` — opts this coordinator out of automatic `@Environment(MyCoordinator.self)` injection into descendant views. Only the coordinator itself is hidden; its ancestors are still injected. See `scaffolding-environment` → `coordinator-injection.md`.
- `codable: true` — makes the generated `Destinations` enum conform to `Codable`, enabling `captureNavigationState()` / `restoreNavigationState(from:)`. Every route function's parameters must then be `Codable` (the compiler enforces it). Closure parameters are incompatible with `codable: true`. See the `scaffolding-state-restoration` skill.

## Good coordinator hygiene

- Route functions stay declarative — construct the view/child coordinator, nothing else. Put imperative navigation in plain `Void` helpers (`func openSettings() { present(.settings) }`), which are never tracked.
- One route function per screen or sub-flow; don't multiplex with parameters that change the returned view's whole identity.
- Views must return `some View`; child coordinators must return `any Coordinatable` (the existential).
