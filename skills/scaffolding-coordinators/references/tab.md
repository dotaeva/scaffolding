# `TabCoordinatable` — tab bars with independent flows

Each tab is a destination: a child coordinator (typical) or a plain view. Provide a `TabItems` container listing the initial tabs.

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
}
```

`TabItems` initializer:

```swift
TabItems<MainTabCoordinator>(
    tabs: [.home, .profile],
    selectedIndex: 1,          // optional initially selected tab
    visibility: .automatic     // initial tab-bar visibility
)
```

## Tab tuple shapes

| Return type | Meaning |
|---|---|
| `(any Coordinatable, some View)` | Child coordinator + label view (the common case) |
| `(some View, some View)` | Content view + label view — view-only tab, no coordinator |
| `(any Coordinatable, TabRole)` / `(some View, TabRole)` | Role instead of a label (e.g. `.search`) |
| `(any Coordinatable, some View, TabRole)` / `(some View, some View, TabRole)` | Label **and** role |

Order matters: coordinator/content first, label second, role last. A tab whose content needs pushes must be a child `FlowCoordinatable` — never a view containing its own `NavigationStack`.

## Selection

```swift
tabCoordinator.selectFirstTab(.home)     // by Meta, first match
tabCoordinator.selectLastTab(.home)      // by Meta, last match
tabCoordinator.select(index: 0)          // zero-based
tabCoordinator.select(id: uuid)          // by tab UUID
```

All return `self` for chaining and have typed-callback / `expecting:` variants that hand you the tab's child coordinator (see `scaffolding-routing` → `deep-linking.md`).

## Intercepting tab taps — `shouldSelect(tab:isReselection:)`

Override to intercept **UI-driven** tab changes. Return `false` to keep the current tab (present something else instead if needed). When the user re-taps the already-selected tab, the hook fires with `isReselection == true` and the return value is ignored — there is no change to veto. Programmatic selection (`selectFirstTab`, `select(index:)`, …) bypasses the hook, so redirecting from inside it does not recurse.

```swift
// Returns Bool ⇒ never macro-tracked — no @ScaffoldingIgnored.
func shouldSelect(tab: Destinations.Meta, isReselection: Bool) -> Bool {
    if isReselection {
        if tab == .home {
            selectFirstTab(.home) { (home: HomeCoordinator) in home.popToRoot() }
        }
        return true
    }
    if tab == .profile && !session.isAuthenticated {
        present(.login)      // show login instead of switching
        return false
    }
    return true
}
```

## Badges

```swift
tabCoordinator.setBadge("3", for: .inbox)   // string badge
tabCoordinator.setBadge(5, for: .inbox)     // numeric; 0 clears
tabCoordinator.setBadge(nil, for: .inbox)   // clear
tabCoordinator.badge(for: .inbox)           // read back: String?
```

## Accessibility identifiers

Give a tab bar item a stable identifier so UI tests and accessibility tools can address it independently of its localized label (a plain `.accessibilityIdentifier()` on the label view never reaches the rendered tab bar item):

```swift
tabCoordinator.setTabAccessibilityIdentifier("tab.inbox", for: .inbox)
tabCoordinator.setTabAccessibilityIdentifier(nil, for: .inbox)   // clear
tabCoordinator.tabAccessibilityIdentifier(for: .inbox)           // read back: String?
```

Identifiers are usually static — set them once in the coordinator's `init`. The framework applies them through the native `TabContent` modifier. With a custom tab bar, read the identifier back and apply `.accessibilityIdentifier` to your own button.

## Dynamic tabs

```swift
tabCoordinator.setTabs([.home, .debug, .profile])   // replace all
tabCoordinator.appendTab(.debug)
tabCoordinator.insertTab(.debug, at: 1)             // index clamped
tabCoordinator.removeFirstTab(.debug)
tabCoordinator.removeLastTab(.debug)
tabCoordinator.isInTabItems(.debug)                 // Bool
```

## Modals and visibility

A `TabCoordinatable` can `present(_:as:)` modals that render **above the whole `TabView`** (login walls, paywalls, what's-new). `isPresentingModal` reports them; `dismissModal()` removes the top one. Tab **children cannot be dismissed** — calling `dismissCoordinator()` on a tab child logs a critical warning and does nothing; remove the tab instead.

```swift
tabCoordinator.setTabBarVisibility(.hidden)   // .automatic / .visible / .hidden
```

## Custom tab bar

To replace the system tab bar with your own UI, stay on `TabCoordinatable` — don't hand-roll tab state in a view. Three pieces:

1. **Hide the native bar** — `TabItems(tabs:, visibility: .hidden)` (or `setTabBarVisibility(.hidden)` later).
2. **Omit the label views.** The `some View` label in the tab tuple only feeds the native tab bar. With a custom bar, tab routes can return plain `any Coordinatable` (or `some View` for a view-only tab) instead of `(any Coordinatable, some View)`. Both are auto-tracked — the macro still generates the cases; the tab simply has no native label.
3. **Build the bar from the macro-generated values.** The bar is an ordinary view: it reads the coordinator from `@Environment`, renders a button per `Destinations.Meta` case, selects via `selectFirstTab(_:)`, and derives selected state from `tabItems.selectedTab`. Badges come from `badge(for:)`, accessibility identifiers from `tabAccessibilityIdentifier(for:)` (apply with `.accessibilityIdentifier` on the button). Attach it in `customize(_:)`, which wraps the whole `TabView`.

```swift
@MainActor @Observable @Scaffoldable
final class MainTabCoordinator: @MainActor TabCoordinatable {
    var tabItems = TabItems<MainTabCoordinator>(
        tabs: [.home, .profile],
        visibility: .hidden          // native bar off
    )

    // No native bar → no label views. Plain returns still generate the cases.
    func home()    -> any Coordinatable { HomeCoordinator() }
    func profile() -> any Coordinatable { ProfileCoordinator() }

    @ScaffoldingIgnored
    func customize(_ view: AnyView) -> some View {
        view.safeAreaInset(edge: .bottom) { CustomTabBar() }
    }
}

struct CustomTabBar: View {
    @Environment(MainTabCoordinator.self) private var coordinator

    var body: some View {
        HStack {
            tabButton(.home,    icon: "house")
            tabButton(.profile, icon: "person")
        }
    }

    private func tabButton(
        _ tab: MainTabCoordinator.Destinations.Meta,
        icon: String
    ) -> some View {
        Button {
            coordinator.selectFirstTab(tab)
        } label: {
            Image(systemName: icon)
                .foregroundStyle(isSelected(tab) ? Color.accentColor : .secondary)
        }
    }

    private func isSelected(_ tab: MainTabCoordinator.Destinations.Meta) -> Bool {
        coordinator.tabItems.tabs
            .first { $0.id == coordinator.tabItems.selectedTab }
            .flatMap { $0.meta as? MainTabCoordinator.Destinations.Meta } == tab
    }
}
```

Caveat: taps on a custom bar go through `selectFirstTab(_:)`, which is **programmatic** selection — `shouldSelect(tab:isReselection:)` is not consulted. If you need guarding or re-tap behavior, call the hook yourself from the button action:

```swift
Button {
    let isReselection = isSelected(tab)
    if coordinator.shouldSelect(tab: tab, isReselection: isReselection) && !isReselection {
        coordinator.selectFirstTab(tab)
    }
}
```
