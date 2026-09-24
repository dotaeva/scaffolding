# Handling Deep Links

Turn a URL, notification, or quick action into one coordinator action that
walks the tree with typed handles.

## Overview

Every navigation call that lands on a child has an `expecting:` overload. It
navigates and returns the child as `T?`, so a deep link is a chain of
ordinary calls:

```swift
extension AppCoordinator {
    func openProfile(userID: Int) {
        dismissAllModals()
        let tabs = setRoot(.authenticated, expecting: MainTabCoordinator.self)
        let profile = tabs?.selectFirstTab(.profile, expecting: ProfileCoordinator.self)
        profile?.popToRoot()
        profile?.route(to: .userDetail(id: userID))
    }
}
```

## Connect the entry point

```swift
WindowGroup {
    coordinator.view
        .onOpenURL { url in
            if let id = parseUserURL(url) { coordinator.openProfile(userID: id) }
        }
}
```

The view calls one action. The chain belongs to the coordinator that owns the
entry point, usually the root.

## Chain typed handles

| Coordinator | Methods with `expecting:` |
|---|---|
| Every coordinator | `present` |
| Flow | `route`, `setRoot`, `popToFirst`, `popToLast` |
| Root | `setRoot` |
| Tab | `selectFirstTab`, `selectLastTab`, `select(index:)`, `select(id:)`, `appendTab`, `insertTab` |
| Split | `setDetail`, `setContent`, `setSidebar` |

```swift
library.setDetail(.planet(id: 4), expecting: PlanetFlowCoordinator.self)?
    .route(to: .moon(id: 2))
```

To configure a child and then wait for its result, combine `expecting:` with
`awaiting:`; see <doc:ModalsAndResults#Configure-the-child-then-await>. To
suppress animation across the chain, see <doc:Essentials#Control-animation>.

## Defer a link until it can run

```swift
var pendingLink: DeepLink?

func handle(_ link: DeepLink) {
    guard session.isAuthenticated else { pendingLink = link; return }
    perform(link)
}

func signIn(token: AuthToken) {
    session = token
    setRoot(.authenticated)
    if let link = pendingLink { pendingLink = nil; perform(link) }
}
```

## Rules

- **Pass the type the route actually builds.** For
  `func authenticated() -> any Coordinatable { MainTabCoordinator() }`, pass
  `MainTabCoordinator.self`. A wrong type returns `nil` but does not undo
  the navigation.
- **Never cache child references.** Each chain gets fresh handles.
- **Don't `await` between steps.** Navigation is synchronous.
- **Decide: reset or reuse.** `setRoot` always builds a fresh branch. Use
  `dismissAllModals()`, `popToRoot()`, or `setRoot` to land on a known
  state; skip them to keep the user's context.

Test a link by asserting the resulting tree; see
<doc:TestingCoordinators#Assert-the-tree>.

## See Also

- <doc:Essentials>
- <doc:Orientation>
- <doc:TestingCoordinators>
