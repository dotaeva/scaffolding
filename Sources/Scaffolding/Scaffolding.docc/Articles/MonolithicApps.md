# Structuring a Monolithic App

Keep every feature in one target, and reach shared coordinators directly
through ancestor lookups.

## Overview

When every coordinator lives in the same module, any coordinator can name any
other. Scaffolding injects each coordinator and all its ancestors into the
environment, and ``Coordinatable/ancestor(ofType:)`` walks up the tree. A deep
screen can reach the root or a tab coordinator without passing references
through every initializer.

Use this shape for apps and prototypes that ship as one target. It stays
manageable as long as each action has one owner: reach an ancestor only to
call an action that ancestor owns. The
[Checklist example](https://github.com/dotaeva/scaffolding/tree/main/Example/Checklist)
is built this way.

## Organize by feature folder

```
MyApp/
├─ App/        AppCoordinator — root branches, deep links
├─ Shell/      MainTabCoordinator
└─ Features/
   ├─ Home/      HomeCoordinator and its screens
   └─ Settings/  SettingsCoordinator and its screens
```

Keep each coordinator's routes, actions, and screens in its folder. Folders
are only a convention here; nothing stops cross-feature references, so the
rules below do.

## Reach an ancestor from a view

Every managed view can read any ancestor:

```swift
struct AccountRow: View {
    @Environment(AppCoordinator.self) private var app

    var body: some View {
        Button("Sign out") { app.signOut() }
    }
}
```

A non-optional lookup crashes when the ancestor is missing — for example in a
preview. Inject it there: `.environment(AppCoordinator())`.

## Reach an ancestor from a coordinator

```swift
extension SettingsCoordinator {
    func restartOnboarding() {
        ancestor(ofType: AppCoordinator.self)?.restartOnboarding()
    }

    func showInbox() {
        ancestor(ofType: MainTabCoordinator.self)?.selectFirstTab(.inbox)
    }
}
```

`ancestor(ofType:)` starts above the receiver and returns the nearest match,
or `nil` when the coordinator is not inside such an ancestor.

## Keep ownership clear

- Call the ancestor's named action (`signOut()`), not a sequence of its
  container calls. The ancestor stays the only owner of its state.
- Look the ancestor up when the action runs. Don't store it: a root swap can
  replace the branch.
- Send data back with results, not ancestor calls:
  `await present(.picker, awaiting: Item.self)` keeps the child reusable.

## Test through the real tree

`ancestor(ofType:)` returns `nil` for a coordinator built alone. Build the
parent, navigate, and take the child from the tree. Run the test on the main
actor, with the imports described in <doc:TestingCoordinators>:

<!-- checked-swift: monolithic-coordinator-test -->
```swift
@MainActor @Test func settingsRestartsOnboarding() throws {
    let app = AppCoordinator().activated()
    app.finishOnboarding()
    let settings = try #require(app.descendant(ofType: MainTabCoordinator.self)?
        .selectFirstTab(.settings, expecting: SettingsCoordinator.self))

    settings.restartOnboarding()

    #expect(app.isRoot(.onboarding))
}
```

## Prepare to split later

Put each ancestor call in one named action on the coordinator, as above.
When the feature moves into its own package, replace that one line with an
injected capability; see <doc:ModularApps#Inject-capabilities-for-app-level-actions>.

## Rules

- Reach an ancestor only for an action it owns, such as a root swap or tab
  switch.
- Never store ancestor or child references.
- Coordinators still don't read `@Environment`; views do.
- Handle `nil` from `ancestor(ofType:)` with optional chaining.

## See Also

- <doc:ModularApps>
- <doc:Essentials>
- <doc:Orientation>
