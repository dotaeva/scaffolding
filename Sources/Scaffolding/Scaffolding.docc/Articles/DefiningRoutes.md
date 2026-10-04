# Defining Routes

Write route functions, use the generated cases, and fix signatures the
macro rejects or skips.

## Overview

`@Scaffoldable` reads the class body and generates a `Destinations` enum with
one case per route function. Parameters become associated values; labels and
default values carry over. A nested `Destinations.Meta` enum names each case
without its payload.

Write `///` or `/** ... */` documentation on the route function. The macro
copies it to the generated case and default-argument convenience factories.
Undocumented routes get no synthesized documentation; implementation bodies
and ordinary comments are omitted.

```swift
@MainActor @Observable @Scaffoldable
final class HomeCoordinator: @MainActor FlowCoordinatable {
    var stack = FlowStack<HomeCoordinator>(root: .home)

    func home() -> some View { HomeView() }                         // .home
    func detail(id: Int, editable: Bool = false) -> some View {     // .detail(id:editable:)
        DetailView(id: id, editable: editable)
    }
    func settings() -> any Coordinatable { SettingsCoordinator() }  // .settings
}

// At a call site
coordinator.route(to: .detail(id: 42))
```

## Return a tracked type

| Return type | Destination | Coordinator |
|---|---|---|
| `some View` | Screen | Any |
| `any Coordinatable` | Child coordinator | Any |
| `(any Coordinatable, some View)` | Child + tab label | ``TabCoordinatable`` |
| `(some View, some View)` | Screen + tab label | ``TabCoordinatable`` |
| `(any Coordinatable, TabRole)`, `(some View, TabRole)` | Content + tab role | ``TabCoordinatable`` |
| `(any Coordinatable, some View, TabRole)`, `(some View, some View, TabRole)` | Content + label + role | ``TabCoordinatable`` |

Everything else is skipped without a diagnostic:

- A concrete return type. `-> LoginCoordinator` is **not** a route; return
  `any Coordinatable`.
- Properties, initializers, `Void` actions, closures, arrays, and other tuples.
- **Anything in an extension.** A member macro sees only the class body.

On a non-tab coordinator, tab tuples compile with a warning and their label
and role are ignored.

## Exclude a helper

Use ``ScaffoldingIgnored()`` only on a class-body function whose return type
is tracked but which is not a route:

```swift
@ScaffoldingIgnored
func customize(_ view: AnyView) -> some View { view.tint(.indigo) }

@ScaffoldingIgnored
func emptyState(message: String) -> some View { Text(message) }
```

Properties, `Void` helpers, and anything in an extension need no annotation.

## Set macro options

| Option | Default | Effect |
|---|---|---|
| `injectsCoordinator` | `true` | Injects the coordinator into its views' environment. `false` hides only this coordinator; ancestors stay visible. |
| `codable` | `false` | Makes `Destinations` `Codable` for <doc:StateRestoration>. Every route parameter must be `Codable`. |

## Use access, conditions, and availability

- Generated code keeps the coordinator's `public` or `package` access.
- Routes inside class-body `#if` blocks keep their conditions, including
  nesting. Mutually exclusive branches may reuse a route name.
- `@available(iOS 27, macOS 27, *)` guards the factory at runtime. Navigation
  methods, restoration, and seeded flow pushes skip unavailable routes;
  `Destinations.isAvailable` lets your code check before choosing an initial
  root, tab, or split column.
- Parameterless cases also carry the availability annotation. Swift forbids
  that annotation on cases with associated values, so payload-bearing cases
  remain constructible. Their payload types must be available at the
  coordinator's deployment floor; the factory still runs only on supported OSes.
- Default arguments use generated main-actor convenience factories. Calls such
  as `.detail()` can read coordinator static state without changing the stored
  payload or its Codable representation. Defaults are evaluated at the call;
  source-location defaults such as `#fileID` and `#line` retain the caller's location,
  including on `@autoclosure` parameters.
- Closure typealiases declared in the class body (including `#if` branches) and
  parenthesized function types work in default-argument factories. An alias may
  be a closure in one branch and a value in another. For a closure alias declared
  elsewhere, write `@escaping` explicitly when the route has default arguments;
  the macro cannot resolve aliases outside the class body.
- Payload types named `Meta` or `Owner` retain their original meaning; the
  generated enum's types do not shadow them.
- A top-level `sending` annotation stays on the route factory, but is removed
  from the enum's stored payload type. Swift checks the transfer at the generated
  factory call. `sending String` works; forwarding a retained non-`Sendable`
  object outside the main actor can still be rejected by Swift. Route
  construction itself is not an exclusive transfer. Annotations inside closure
  parameter/result types are preserved.

## Use the generated types

- `Destinations` — pass it to `route(to:)`, `present(_:as:)`, `setRoot(_:)`,
  `setDetail(_:)`, and container initializers.
- `Destinations.Meta` — used by `popToFirst(_:)`, `isInStack(_:)`,
  `selectFirstTab(_:)`, `badge(for:)`, `shouldSelect(tab:isReselection:)`,
  and `\.destination.meta`. Queries and `.distinct` compare `Meta`, so
  `.detail(id: 1)` matches `.detail(id: 2)`.
- ``Destinationable`` conformance, so the framework can build a
  ``Destination`` from each case.

## Rules

Route factories must be synchronous, non-throwing instance methods with
unique names and storable parameter types. These are compile errors:

- Two routes with the same base name. Rename one or ignore it.
- Generic or opaque (`some View`) parameters, variadic, or `inout` parameters.
- `unavailable`, `obsoleted`, or Swift-version availability on a route. Use
  `#if` instead.
- `@Scaffoldable` on a non-class, or on a class conforming to none of the
  four coordinator protocols.
- Non-literal macro options. Pass `true` or `false` directly.

## See Also

- <doc:Essentials>
- <doc:Flows>
