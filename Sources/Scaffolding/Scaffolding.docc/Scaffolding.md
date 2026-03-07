# ``Scaffolding``

Macro-powered SwiftUI navigation that implements the Coordinator pattern with
type-safe routes and minimal boilerplate.

@Metadata {
    @PageColor(blue)
}

## Overview

Scaffolding lets you define navigation routes as plain Swift functions on
coordinator classes. The ``Scaffoldable()`` macro inspects those functions at
compile time and generates a `Destinations` enum automatically — no manual
enums, no switch statements, no boilerplate.

```swift
@Scaffoldable @Observable
final class HomeCoordinator: @MainActor FlowCoordinatable {
    var stack = FlowStack<HomeCoordinator>(root: .home)

    func home() -> some View { HomeView() }
    func detail(item: String) -> some View { DetailView(item: item) }
    func settings() -> any Coordinatable { SettingsCoordinator() }
}
```

Coordinators conform to one of three protocols depending on the navigation
pattern:

- **``FlowCoordinatable``** — Push/pop navigation stacks with sheet and
  full-screen-cover support.
- **``TabCoordinatable``** — Tab bar interfaces where each tab owns its own
  coordinator.
- **``RootCoordinatable``** — Atomic root switches for authentication flows
  and app-wide state changes.

Navigation is performed by calling methods like `route(to:)`, `pop()`,
`setRoot(_:)`, or tab selection on the coordinator. Coordinators are
automatically injected into the SwiftUI environment, so any child view can
access its nearest coordinator with `@Environment`.

## Topics

### Essentials

- <doc:MeetScaffolding>
- <doc:YourFirstScaffoldingProject>

### Coordinator Protocols

- ``FlowCoordinatable``
- ``TabCoordinatable``
- ``RootCoordinatable``

### Core Protocol

- ``Coordinatable``

### Destinations

- ``Destinationable``
- ``DestinationMeta``
- ``Destination``
- ``DestinationType``
- ``PresentationType``

### State Containers

- ``FlowStack``
- ``Root``
- ``TabItems``

### Macros

- ``Scaffoldable()``
- ``ScaffoldingIgnored()``
