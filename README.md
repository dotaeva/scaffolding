<div align="center">

# Scaffolding 目

**Macro-powered SwiftUI navigation that stays out of your way.**

[![Swift 6.2+](https://img.shields.io/badge/Swift-6.2+-F05138.svg?style=flat&logo=swift)](https://swift.org)
[![iOS 18+](https://img.shields.io/badge/iOS-18%2B-007AFF.svg?style=flat&logo=apple)](https://developer.apple.com/ios/)
[![macOS 15+](https://img.shields.io/badge/macOS-15%2B-000000.svg?style=flat&logo=apple)](https://developer.apple.com/macos/)
[![Swift Package Manager](https://img.shields.io/badge/SPM-compatible-brightgreen.svg?style=flat)](https://swift.org/package-manager/)

Define routes as functions. Get type-safe navigation for free.

**[Documentation](https://dotaeva.github.io/scaffolding/documentation/scaffolding)** ·
**[Getting Started](https://dotaeva.github.io/scaffolding/documentation/scaffolding/meetscaffolding)** ·
**[Migrating from Stinsen](https://dotaeva.github.io/scaffolding/documentation/scaffolding/migratingfromstinsen)**

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

That's it. The `@Scaffoldable` macro generates a `Destinations` enum from your
methods — no manual enums, no switch statements, no boilerplate.

```swift
coordinator.route(to: .detail(item: selectedItem))   // push
coordinator.present(.settings, as: .sheet)           // sheet (sub-flow)
coordinator.pop()
```

Views read their coordinator from `@Environment` and call it. Navigation state
never lives in the UI layer, so flows compose across module boundaries and the
whole navigation layer is unit-testable without rendering a view.

Four protocols cover the structure of an app:
[`FlowCoordinatable`](https://dotaeva.github.io/scaffolding/documentation/scaffolding/flowcoordinatable)
for push/pop stacks,
[`TabCoordinatable`](https://dotaeva.github.io/scaffolding/documentation/scaffolding/tabcoordinatable)
for tab bars where each tab owns a coordinator,
[`RootCoordinatable`](https://dotaeva.github.io/scaffolding/documentation/scaffolding/rootcoordinatable)
for atomic root swaps like authentication, and
[`SplitCoordinatable`](https://dotaeva.github.io/scaffolding/documentation/scaffolding/splitcoordinatable)
for sidebar and detail columns.

> ⚠ **Don't nest `NavigationStack` inside a flow.** `FlowCoordinatable` *is* the
> `NavigationStack`, and SwiftUI doesn't compose stacks with each other. If a
> screen needs its own hierarchy, route to a child coordinator instead.

---

## Installation

Add Scaffolding via Swift Package Manager:

```
https://github.com/dotaeva/scaffolding.git
```

The package exposes two libraries: **Scaffolding** for your app target, and
**ScaffoldingTesting** for your test target. Don't link `ScaffoldingTesting`
into an app target; it imports Swift Testing.

**Requirements:** iOS 18+ · macOS 15+ · tvOS 18+ · watchOS 11+ · macCatalyst 18+ · Swift 6.2 · Xcode 16+

---

## Documentation

The full documentation lives at
**[dotaeva.github.io/scaffolding](https://dotaeva.github.io/scaffolding/documentation/scaffolding)**:

- [**Meet Scaffolding**](https://dotaeva.github.io/scaffolding/documentation/scaffolding/meetscaffolding) — the guided tour: coordinators, routing, environment access, composition, dismissal.
- [**Guides**](https://dotaeva.github.io/scaffolding/documentation/scaffolding) — one per task:
  [first project](https://dotaeva.github.io/scaffolding/documentation/scaffolding/meetscaffolding),
  [tabs and flows](https://dotaeva.github.io/scaffolding/documentation/scaffolding/tabbars),
  [authentication](https://dotaeva.github.io/scaffolding/documentation/scaffolding/rootswitching),
  [modal sub-flows](https://dotaeva.github.io/scaffolding/documentation/scaffolding/modalsandresults),
  [deep linking](https://dotaeva.github.io/scaffolding/documentation/scaffolding/deeplinking),
  [state restoration](https://dotaeva.github.io/scaffolding/documentation/scaffolding/staterestoration),
  [testing](https://dotaeva.github.io/scaffolding/documentation/scaffolding/testingcoordinators).
- [**Migrating from Stinsen**](https://dotaeva.github.io/scaffolding/documentation/scaffolding/migratingfromstinsen) — concept map and a migration checklist.
- **API reference** — every type, method, and both macros:
  [`@Scaffoldable`](<https://dotaeva.github.io/scaffolding/documentation/scaffolding/scaffoldable(injectscoordinator:codable:)>),
  [`@ScaffoldingIgnored`](<https://dotaeva.github.io/scaffolding/documentation/scaffolding/scaffoldingignored()>).

---

## Agent skills

This repo doubles as a [Claude Code](https://claude.com/claude-code) plugin
marketplace shipping five skills that teach coding agents the current API —
coordinators, routing, `@Environment` values, state restoration, and testing:

```sh
claude plugin marketplace add dotaeva/scaffolding && claude plugin install scaffolding@scaffolding
```

Or from inside a session: `/plugin marketplace add dotaeva/scaffolding` then
`/plugin install scaffolding@scaffolding`. Add `--scope project` (CLI) to commit
the plugin to a single project instead of installing it for your user.

Skills load on demand, so the standing cost is only the ~1.7k tokens of skill
descriptions. For agents without plugin support, [`AGENTS.md`](AGENTS.md) covers
the same ground in one file.

---

## Example Project

[`Example/Checklist`](Example/Checklist) is a to-do app for iPhone, iPad, and Mac
that exercises the whole API surface — a root coordinator swapping onboarding
and the main app, tabs on iPhone and a three-column split view on iPad and Mac,
modal sub-flows, awaited results, deep links, state restoration, and
[unit tests](Example/Checklist/Tests). It's a plain Xcode project with no
generators or extra tooling:

```sh
open Example/Checklist/Checklist.xcodeproj
```

⌘R runs the app, ⌘U runs the tests.

[`Example/Atlas`](Example/Atlas) splits a travel app into ten Swift packages to
show features composed across module boundaries.

---

<div align="center">

**MIT License**

</div>
