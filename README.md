<div align="center">

# Scaffolding 目

**Macro-powered SwiftUI navigation that stays out of your way.**

[![Swift 6.2+](https://img.shields.io/badge/Swift-6.2+-F05138.svg?style=flat&logo=swift)](https://swift.org)
[![iOS 18+](https://img.shields.io/badge/iOS-18%2B-007AFF.svg?style=flat&logo=apple)](https://developer.apple.com/ios/)
[![macOS 15+](https://img.shields.io/badge/macOS-15%2B-000000.svg?style=flat&logo=apple)](https://developer.apple.com/macos/)
[![Swift Package Manager](https://img.shields.io/badge/SPM-compatible-brightgreen.svg?style=flat)](https://swift.org/package-manager/)

Define routes as functions. Get type-safe navigation for free.

**[Documentation](https://dotaeva.github.io/scaffolding/documentation/scaffolding)** ·
**[Tutorials](https://dotaeva.github.io/scaffolding/tutorials/table-of-contents)** ·
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

Three protocols cover the structure of an app:
[`FlowCoordinatable`](https://dotaeva.github.io/scaffolding/documentation/scaffolding/flowcoordinatable)
for push/pop stacks,
[`TabCoordinatable`](https://dotaeva.github.io/scaffolding/documentation/scaffolding/tabcoordinatable)
for tab bars where each tab owns a coordinator, and
[`RootCoordinatable`](https://dotaeva.github.io/scaffolding/documentation/scaffolding/rootcoordinatable)
for atomic root swaps like authentication.

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
- [**Tutorials**](https://dotaeva.github.io/scaffolding/tutorials/table-of-contents) — build one app step by step:
  [first project](https://dotaeva.github.io/scaffolding/tutorials/scaffolding/yourfirstscaffoldingproject),
  [tabs and flows](https://dotaeva.github.io/scaffolding/tutorials/scaffolding/tabsandflows),
  [authentication](https://dotaeva.github.io/scaffolding/tutorials/scaffolding/authenticationflow),
  [modal sub-flows](https://dotaeva.github.io/scaffolding/tutorials/scaffolding/modalsubflows),
  [deep linking](https://dotaeva.github.io/scaffolding/tutorials/scaffolding/deeplinking),
  [state restoration](https://dotaeva.github.io/scaffolding/tutorials/scaffolding/staterestoration),
  [testing](https://dotaeva.github.io/scaffolding/tutorials/scaffolding/testingcoordinators).
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

[`Example/Weather`](Example/Weather) is a Weather-style app that exercises the
whole library from a single multiplatform target — iPhone, iPad, and native
macOS. iPhone gets a `TabCoordinatable` shell (tab tuples with labels and a
`TabRole`, a badge, a dynamic Radar tab, `shouldSelect` interception); iPad and
macOS get a `SplitCoordinatable` shell (sidebar → detail replacement, a runtime
Hourly content column, visibility control, split-hosted sheets). Both shells
feed the same flows: pushes with every `RoutePolicy`, `replaceLast`, every pop
variant, awaited results (`routeAndWait`, `presentAndWait`,
`present(_:awaiting:)` + `dismissCoordinator(returning:)`), presenter-side
sheet configuration and dismissal, an atomic onboarding root swap, `weather://`
deep links through both layouts, whole-tree state restoration, and the
orientation/debug surface. Every source file stays under 100 lines, and
[40 unit tests](Example/Weather/Tests) run against the shipping coordinators on
both platforms:

```sh
open Example/Weather/Weather.xcodeproj
```

⌘R runs the app (pick an iPhone, iPad, or My Mac destination), ⌘U runs the
tests. Shake (⌃⌘Z in the simulator) or ⇧⌘D on macOS dumps the live
coordinator tree.

---

<div align="center">

**MIT License**

</div>
