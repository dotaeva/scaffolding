# Migrating from Stinsen

Move route declarations, environment access, and navigation calls to
Scaffolding one flow at a time.

## Overview

Both libraries put navigation on coordinators. In Scaffolding, routes are
class-body functions, views read the coordinator itself, and the framework
places native containers for you. The
[Stinsen Parity example](https://github.com/dotaeva/scaffolding/tree/main/Example/StinsenParity)
ports [Stinsen's](https://github.com/rundfunk47/stinsen) login, todo, and tab demo.

> Important: Scaffolding needs Swift 6.2 / Xcode 26 or later and iOS 18,
> macOS 15, Mac Catalyst 18, tvOS 18, or watchOS 11. Check this first.

## Map the concepts

| Stinsen | Scaffolding |
|---|---|
| `NavigationCoordinatable` | ``FlowCoordinatable`` |
| `TabCoordinatable` | ``TabCoordinatable`` |
| Multiple `@Root` routes | ``RootCoordinatable`` |
| `NavigationViewCoordinator` | Return the child coordinator directly |
| `ViewWrapperCoordinator` | `customize(_:)` |
| `NavigationStack(initial:)` | ``FlowStack`` |
| `TabChild(startingItems:)` | ``TabItems`` |
| `@Root` / `@Route` properties | Class-body route functions |
| `@EnvironmentObject` router | `@Environment(MyCoordinator.self)` |
| Global router lookup | Initializer injection or `ancestor(ofType:)` |
| `.view()` | `.view` |

When one file imports both libraries, qualify ambiguous names, such as
`Scaffolding.Coordinatable`.

## Convert a flow

A login root, a pushed registration flow, and a modal forgot-password screen:

```swift
import SwiftUI
import Scaffolding

@MainActor @Observable @Scaffoldable
final class LoginCoordinator: @MainActor FlowCoordinatable {
    var stack = FlowStack<LoginCoordinator>(root: .login)

    func login() -> some View { LoginScreen() }
    func registration() -> any Coordinatable { RegistrationCoordinator() }
    func forgotPassword() -> some View { ForgotPasswordScreen() }
}
```

1. Replace property-wrapped routes with **class-body** functions.
2. Return `some View` for screens and `any Coordinatable` for child flows —
   never the concrete coordinator type.
3. Seed the root or path through `FlowStack`'s initializer.
4. Choose push or modal at the call site: `route(to: .registration)` pushes;
   `present(.forgotPassword)` presents.
5. Remove navigation wrappers. Never add a `NavigationStack` in a route.

## Update views

```swift
struct LoginScreen: View {
    @Environment(LoginCoordinator.self) private var coordinator

    var body: some View {
        Form {
            Button("Register") { coordinator.route(to: .registration) }
            Button("Forgot password") { coordinator.present(.forgotPassword) }
        }
    }
}
```

Ancestors are injected too. A view model takes its coordinator through its
initializer; there is no global router.

## Translate calls

| Intent | Scaffolding |
|---|---|
| Push with input | `route(to: .detail(id: itemID))` |
| Present a sheet / cover | `present(.settings)`, `present(.player, as: .fullScreenCover)` |
| Prevent swipe dismissal | `.interactiveDismissDisabled(true)` on the presented content |
| Go back | `pop()` |
| Close the visible modal | `dismissPresentedModal()` |
| Clear the flow | `popToRoot()` |
| Focus the first matching route | `popToFirst(.detail)` |
| Close the child flow | `dismissCoordinator()` |
| Switch the app branch | `setRoot(.authenticated)` on a root coordinator |
| Walk into a tab | `selectFirstTab(.todos, expecting: TodosCoordinator.self)?.route(to: .todo(id: id))` |
| Receive a completion value | `await present(.limitPicker, awaiting: Decimal.self)`, answered by `dismissCoordinator(returning:)` |

## Migrate in order

1. Port a leaf flow and its views.
2. Check push, back, modal dismissal, and results.
3. Compose it into tabs or a root, then check deep links.
4. Port persistence last; see <doc:StateRestoration>.
5. Add coordinator tests; see <doc:TestingCoordinators>.

## Rules

- `pop()` can remove a modal, and on an empty stack it dismisses the
  coordinator.
- Modals queue per host. To stack a second modal, present it from the first
  modal's coordinator.
- `setRoot` always builds a fresh branch. Check `isRoot(_:)` first, and never
  use `setRoot(_:expecting:)` as a lookup.
- `.distinct` compares cases, not associated values.
- Cancelling an awaiting task returns `nil` and **leaves the screen open**.
  Keep constructor callbacks for repeated updates before dismissal.

## See Also

- <doc:Essentials>
- <doc:DefiningRoutes>
- <doc:ModalsAndResults>
