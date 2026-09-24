# Building Tab Bars

Define tabs as routes, then control selection, badges, taps, and custom bars.

## Overview

A ``TabCoordinatable`` renders a `TabView`. Each tab route usually returns a
child flow and a label. Each flow keeps its own stack while another tab is
selected.

```swift
@MainActor @Observable @Scaffoldable
final class MainTabCoordinator: @MainActor TabCoordinatable {
    var tabItems = TabItems<MainTabCoordinator>(tabs: [.home, .profile])

    func home() -> (any Coordinatable, some View) {
        (HomeCoordinator(), Label("Home", systemImage: "house"))
    }
    func profile() -> (any Coordinatable, some View) {
        (ProfileCoordinator(), Label("Profile", systemImage: "person"))
    }
    func search() -> (any Coordinatable, TabRole) {
        (SearchCoordinator(), .search)
    }
}
```

`TabItems(tabs:selectedIndex:visibility:)` sets the initial tabs, selection,
and native bar visibility. <doc:DefiningRoutes> lists every tab route shape.

## Keep history across tabs

@Row(numberOfColumns: 3) {
    @Column(size: 1) {
        @Video(source: atlas-tab-history.mp4, poster: atlas-tab-history-poster.png, alt: "Discover pushes the Dolomites place and its Field notes. The user switches to Saved, then back to Discover, which still shows Field notes.")
    }
    @Column(size: 2) {
        Recorded in the [Atlas example](https://github.com/dotaeva/scaffolding/tree/main/Example/Atlas) on an **iPhone 17 simulator with iOS 26.4**.

        1. **Open The Dolomites.** Explore pushes the Places coordinator, which lives in another package.
        2. **Open Field notes.** Places pushes its own screen onto the same stack.
        3. **Switch to Saved.** That tab has its own stack and history.
        4. **Return to Discover.** Field notes is still on top.
    }
}

## Select tabs

```swift
selectFirstTab(.profile)
select(index: 0)
selectFirstTab(.profile, expecting: ProfileCoordinator.self)?.popToRoot()
```

Read the selection with `selectedTabDestination` or `selectedTabIndex`.
Selecting keeps each tab's content and history; `setTabs(_:)` builds new tabs.

## Intercept taps

Override ``TabCoordinatable/shouldSelect(tab:isReselection:)`` to guard
**user taps**. Return `false` to keep the current tab. A re-tap arrives with
`isReselection == true`; its return value is ignored.

```swift
func shouldSelect(tab: Destinations.Meta, isReselection: Bool) -> Bool {
    if isReselection {
        if tab == .home {
            selectFirstTab(.home, expecting: HomeCoordinator.self)?.popToRoot()
        }
        return true
    }
    guard tab != .profile || session.isAuthenticated else {
        present(.login)
        return false
    }
    return true
}
```

Programmatic selection bypasses this hook, so selecting from inside it cannot
recurse.

## Build a custom bar

Keep the coordinator and replace only the chrome:

1. Hide the native bar with `TabItems(tabs: [...], visibility: .hidden)`.
2. Return plain `any Coordinatable` or `some View` from tab routes; labels
   are optional.
3. Render buttons that read `selectedTabDestination` and call
   `selectFirstTab(_:)`, and attach the bar in `customize(_:)`:

```swift
extension MainTabCoordinator {
    func customize(_ view: AnyView) -> some View {
        view.safeAreaInset(edge: .bottom) { CustomTabBar() }
    }
}
```

Custom taps are programmatic, so call the guard yourself when it matters:

```swift
Button("Home", systemImage: "house") {
    let isReselection = coordinator.selectedTabDestination == .home
    if coordinator.shouldSelect(tab: .home, isReselection: isReselection), !isReselection {
        coordinator.selectFirstTab(.home)
    }
}
```

Apply `badge(for:)` and `tabAccessibilityIdentifier(for:)` to your buttons,
and give icon-only buttons an accessible label.

## API

| Intent | Method |
|---|---|
| Select | ``TabCoordinatable/selectFirstTab(_:)``, ``TabCoordinatable/selectLastTab(_:)``, ``TabCoordinatable/select(index:)``, ``TabCoordinatable/select(id:)``, plus `expecting:` overloads |
| Read selection | `selectedTabDestination`, `selectedTabIndex`, ``TabCoordinatable/isInTabItems(_:)`` |
| Change tabs | ``TabCoordinatable/setTabs(_:)``, ``TabCoordinatable/appendTab(_:)``, ``TabCoordinatable/insertTab(_:at:)``, ``TabCoordinatable/removeFirstTab(_:)``, ``TabCoordinatable/removeLastTab(_:)`` |
| Badge (`String?` or `Int`) | `setBadge(_:for:)`, ``TabCoordinatable/badge(for:)`` |
| UI-test identifier | ``TabCoordinatable/setTabAccessibilityIdentifier(_:for:)``, ``TabCoordinatable/tabAccessibilityIdentifier(for:)`` |
| Native bar | ``TabCoordinatable/setTabBarVisibility(_:)`` |
| Guard taps | Override ``TabCoordinatable/shouldSelect(tab:isReselection:)`` |
| Default animation | ``TabCoordinatable/setTransitionAnimation(_:)`` |

## Rules

- Set badges and identifiers on the coordinator. An `.accessibilityIdentifier`
  on the label view does not reach the native tab item.
- Bar visibility applies on iOS, iPadOS, and Mac Catalyst only. Badges are not
  rendered on tvOS or watchOS.
- Tab children are structural: they cannot `dismissCoordinator()`. Remove the
  tab instead. Modals presented from a tab dismiss normally.
- Implement re-tap-to-pop in `shouldSelect`, not in the flow.
- A ``SplitCoordinatable`` can be a tab.

## See Also

- <doc:Essentials>
- <doc:Flows>
- <doc:DeepLinking>
