# Getting Started

Install Scaffolding, build a flow, and add a child feature.

## Overview

This guide builds a two-screen library app, then adds a settings feature
with its own coordinator. Read <doc:Essentials> next. Coming from existing
code? See <doc:NativeComparison> or <doc:MigratingFromStinsen>.

## Install the package

Add `https://github.com/dotaeva/scaffolding.git` with Xcode's **Add Package
Dependencies** and link **Scaffolding** to your app. Link
**ScaffoldingTesting** only to test targets.

Requires Swift 6.2 / Xcode 26 or later. Minimum deployment: iOS 18, macOS 15,
Mac Catalyst 18, tvOS 18, watchOS 11.

## Build a flow

Replace a new SwiftUI app's entry file with this example. Delete the
template's other `@main` declaration.

<!-- checked-swift: first-flow -->
```swift
import SwiftUI
import Scaffolding

@MainActor @Observable @Scaffoldable
final class LibraryCoordinator: @MainActor FlowCoordinatable {
    var stack = FlowStack<LibraryCoordinator>(root: .library)

    func library() -> some View { LibraryView() }
    func book(title: String) -> some View { BookView(title: title) }
}

struct LibraryView: View {
    @Environment(LibraryCoordinator.self) private var coordinator

    var body: some View {
        List {
            Button("Open The Odyssey") {
                coordinator.route(to: .book(title: "The Odyssey"))
            }
        }
        .navigationTitle("Library")
    }
}

struct BookView: View {
    let title: String
    @Environment(LibraryCoordinator.self) private var coordinator

    var body: some View {
        VStack(spacing: 16) {
            Text(title).font(.title)
            Button("Back to library") { coordinator.pop() }
        }
        .padding()
        .navigationTitle(title)
    }
}

@main
struct LibraryApp: App {
    @State private var coordinator = LibraryCoordinator()

    var body: some Scene {
        WindowGroup { coordinator.view }
    }
}
```

Tap **Open The Odyssey**: the coordinator pushes `BookView`, and Back pops it.
Neither view holds a path or a navigation container.

- ``FlowStack`` holds the root and the pushed screens.
- `@Scaffoldable` turns `library()` and `book(title:)` into the `.library`
  and `.book(title:)` cases.
- `coordinator.view` renders the flow and injects the coordinator into its
  views.

## Add a child feature

A route can return a coordinator instead of a view. Add this route to
`LibraryCoordinator`'s class body:

```swift
func settings() -> any Coordinatable { SettingsCoordinator() }
```

Then define the child:

<!-- checked-swift: first-flow-settings -->
```swift
@MainActor @Observable @Scaffoldable
final class SettingsCoordinator: @MainActor FlowCoordinatable {
    var stack = FlowStack<SettingsCoordinator>(root: .settings)

    func settings() -> some View { SettingsView() }
}

struct SettingsView: View {
    @Environment(SettingsCoordinator.self) private var coordinator

    var body: some View {
        Form {
            Button("Done") { coordinator.dismissCoordinator() }
        }
        .navigationTitle("Settings")
    }
}
```

Call `coordinator.present(.settings)` from `LibraryView`. Settings owns its own
stack and can grow without changing the caller. Inside it, `pop()` goes back
one screen and `dismissCoordinator()` closes the whole flow.

## Name multi-step actions

A view may make one direct call. When an action combines steps, name it on the
coordinator, in an extension so the macro doesn't treat it as a route:

```swift
extension LibraryCoordinator {
    func openBook(title: String) {
        popToRoot()
        route(to: .book(title: title))
    }

    func customize(_ view: AnyView) -> some View {
        view.tint(.indigo)
    }
}
```

`customize(_:)` wraps everything the coordinator renders.

## See Also

- <doc:Essentials>
- <doc:Flows>
- <doc:ModalsAndResults>
