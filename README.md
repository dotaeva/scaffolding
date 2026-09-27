<div align="center">

# Scaffolding 目

**SwiftUI navigation across feature boundaries.**

[![Swift 6.2+](https://img.shields.io/badge/Swift-6.2+-F05138.svg?style=flat&logo=swift)](https://swift.org)
[![iOS 18+](https://img.shields.io/badge/iOS-18%2B-007AFF.svg?style=flat&logo=apple)](https://developer.apple.com/ios/)
[![macOS 15+](https://img.shields.io/badge/macOS-15%2B-000000.svg?style=flat&logo=apple)](https://developer.apple.com/macos/)

**[Getting Started](https://dotaeva.github.io/scaffolding/documentation/scaffolding/meetscaffolding)** ·
**[Documentation](https://dotaeva.github.io/scaffolding/documentation/scaffolding)** ·
**[Atlas Example](Example/Atlas)**

</div>

Each feature owns a coordinator and keeps its screens internal. Scaffolding
composes them into native SwiftUI stacks, tabs, sheets, and split views.

## Define routes as functions

```swift
@MainActor @Observable @Scaffoldable
final class HomeCoordinator: @MainActor FlowCoordinatable {
    var stack = FlowStack<HomeCoordinator>(root: .home)

    func home() -> some View { HomeView() }
    func detail(item: Item) -> some View { DetailView(item: item) }
    func settings() -> any Coordinatable { SettingsCoordinator() }
}
```

`@Scaffoldable` generates typed destinations. Views request navigation from
their coordinator:

```swift
coordinator.route(to: .detail(item: selectedItem))
coordinator.present(.settings, as: .sheet)
```

Scaffolding provides the navigation containers; route views don't add their own.
Follow [Getting Started](https://dotaeva.github.io/scaffolding/documentation/scaffolding/meetscaffolding)
for a complete app, including views and environment access.

## Installation

Add Scaffolding via Swift Package Manager:

```
https://github.com/dotaeva/scaffolding.git
```

Link **Scaffolding** to your app and **ScaffoldingTesting** only to test targets.

**Requirements:** Swift 6.2+ · Xcode 26+

**Platforms:** iOS 18+ · macOS 15+ · tvOS 18+ · watchOS 11+ · Mac Catalyst 18+

## Examples

[**Atlas**](Example/Atlas) demonstrates navigation across feature packages,
with recordings, source walkthroughs, and tests.
[**Checklist**](Example/Checklist) is a compact to-do app for iPhone, iPad, and Mac.

## Agent skills

[Agent skills](skills) teach coding agents the current API. Install in Claude Code:

```sh
claude plugin marketplace add dotaeva/scaffolding && claude plugin install scaffolding@scaffolding
```

For other agents, start with [AGENTS.md](AGENTS.md).

---

[MIT License](LICENSE)
