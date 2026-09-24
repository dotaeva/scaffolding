# Migrating from SwiftUI Navigation

Map native navigation to coordinator calls. The containers and view
modifiers stay SwiftUI's.

## Overview

A self-contained screen graph can use SwiftUI navigation directly. Use
Scaffolding when flows cross features, open from deep links, or need tests
without UI. What changes is who owns navigation state: coordinators, not
views. The tables below map **intent**, not identical operations.

## Replace paths with a flow

| Native | Scaffolding |
|---|---|
| `NavigationStack` with a root | `FlowStack(root: .library)` on a ``FlowCoordinatable`` |
| `navigationDestination` | A class-body route: `func book(id: Int) -> some View` |
| `NavigationLink(value:)` | `Button { coordinator.route(to: .book(id: 42)) }` |
| `path.removeLast()` | `pop()`; `pop(_:)` stops at the root |
| `path = []` | `popToRoot()`, which also clears the flow's modals |
| An initial `NavigationPath` | `FlowStack(root:pushing:)` |

Views drop `NavigationPath`, `navigationDestination`, and value-based links:

```swift
struct BookRow: View {
    @Environment(LibraryCoordinator.self) private var coordinator
    let bookID: Int
    let title: String

    var body: some View {
        Button(title) { coordinator.route(to: .book(id: bookID)) }
    }
}
```

## Replace flow-owned sheets

Keep view-only sheets native. Use a route when the screen belongs to a flow,
opens from code, or returns a result.

| Native | Scaffolding |
|---|---|
| `.sheet(item:)` owned by a flow | `present(.settings)` |
| `.fullScreenCover` | `present(.onboarding, as: .fullScreenCover)` |
| `.presentationDetents`, `.interactiveDismissDisabled` | Same modifiers, on the presented view or in the child's `customize(_:)` |
| Setting the item to `nil` | `dismissPresentedModal()` from the presenter |
| `@Environment(\.dismiss)` | Still works; `destination.dismiss()` and `dismissCoordinator()` also close |
| Passing a result back through a binding | `await present(.picker, awaiting: Item.self)` |

## Replace tab selection

| Native | Scaffolding |
|---|---|
| `TabView` with `Tab` items | ``TabCoordinatable`` with `TabItems(tabs:)` and tuple routes |
| `selection` binding | `selectFirstTab(_:)`, `select(index:)`, `selectedTabDestination` |
| `.badge` | `setBadge(_:for:)` |
| `.toolbar(.hidden, for: .tabBar)` | `setTabBarVisibility(.hidden)` |
| Intercepting selection changes | Override `shouldSelect(tab:isReselection:)` |

## Replace roots and split views

| Native | Scaffolding |
|---|---|
| `if isLoggedIn { … } else { … }` | ``RootCoordinatable`` with `setRoot(_:)` |
| `NavigationSplitView` | ``SplitCoordinatable`` with `SplitColumns(sidebar:detail:)` |
| A middle column | `content:` in the initializer, or `setContent(_:)` |
| Detail from list selection | `setDetail(_:)`; keep `List(selection:)` for highlight |
| `columnVisibility` binding | `setColumnVisibility(_:)` |
| `preferredCompactColumn` binding | `setPreferredCompactColumn(_:)` |
| A stack in a column | Return a child ``FlowCoordinatable`` for that column |

## Keep the rest in SwiftUI

- `navigationTitle`, `toolbar`, `searchable`, and other appearance modifiers
  stay on your views. Shared chrome goes in `customize(_:)`.
- `.transition(_:)` still styles view insertion. Navigation animation is
  `setTransitionAnimation(_:)` or a `withNavigationTransaction` scope.
- `.onOpenURL` calls one coordinator action; see <doc:DeepLinking>.

## Rules

- `pop()` can remove a modal, and on an empty stack it dismisses the
  coordinator.
- `setRoot` and column setters build fresh branches, even for the same case.
  Guard on domain state to keep one.
- Programmatic tab selection bypasses the tap hook.
- Never keep a `NavigationStack` inside a route view.

## See Also

- <doc:Essentials>
- <doc:Flows>
- <doc:ModalsAndResults>
