// Side-by-side migration snippets for /docs/changelog.

export const CODE_VIEW_BEFORE = `// 2.x
@main
struct MyApp: App {
    @State private var coordinator = AppCoordinator()

    var body: some Scene {
        WindowGroup {
            coordinator.view()      // function call
        }
    }
}`;

export const CODE_VIEW_AFTER = `// 3.0
@main
struct MyApp: App {
    @State private var coordinator = AppCoordinator()

    var body: some Scene {
        WindowGroup {
            coordinator.view        // computed property — no parens
        }
    }
}`;

export const CODE_ROUTE_BEFORE = `// 2.x — one route() did everything.
coordinator.route(to: .detail(item: planet))           // push (default)
coordinator.route(to: .settings, as: .sheet)           // sheet
coordinator.route(to: .login,    as: .fullScreenCover) // full-screen cover`;

export const CODE_ROUTE_AFTER = `// 3.0 — push and present are explicitly different calls.
coordinator.route(to: .detail(item: planet))           // push only
coordinator.present(.settings, as: .sheet)             // sheet
coordinator.present(.login,    as: .fullScreenCover)   // full-screen cover

// route(to:) no longer takes \`as:\` — pushes are the only thing it does.
// present(_:as:) accepts ModalPresentationType (sheet / fullScreenCover)
// at the call site; push is not a valid modal style by definition.`;

// 3.1.0 — typed `present<T>` overload, mirroring the existing typed
// route / setRoot / selectFirstTab / etc. variants.
export const CODE_PRESENT_TYPED = `// 3.1 — present(_:as:) gains a \`<T: Coordinatable>\` overload
// that hands you the resolved child once the modal lands.

func openSubscriptionAt(planId: String) {
    present(.subscription, as: .sheet) { (sub: SubscriptionCoordinator) in
        // Seed the freshly-presented sub-flow before SwiftUI commits
        // the sheet — no IDs to forward, no @Environment lookups.
        sub.preselect(planId: planId)
    }
}`;

export const CODE_PRESENT_HOSTS = `// 3.0 — present(_:as:) is now available on every coordinator type.

@Scaffoldable @Observable
final class MainTabCoordinator: @MainActor TabCoordinatable {
    var tabItems = TabItems<MainTabCoordinator>(tabs: [.feed, .profile])

    func feed()    -> (any Coordinatable, some View) { /* … */ }
    func profile() -> (any Coordinatable, some View) { /* … */ }

    func upgrade() -> any Coordinatable { UpgradeCoordinator() }

    func showUpgrade() {
        present(.upgrade, as: .sheet)   // tab coordinator hosts the sheet
    }
}`;

export const CODE_CALLBACK_BEFORE = `// 2.x — \`<T>\` was unconstrained, the closure was labelled \`value:\`,
// and \`route\` carried the \`as:\` parameter that's now on \`present\`.
appCoordinator.setRoot(.authenticated, value: { (tab: MainTabCoordinator) in
    tab.selectFirstTab(.profile, value: { (profile: ProfileCoordinator) in
        profile.route(to: .userDetail(id: 123), as: .push)
    })
})`;

export const CODE_CALLBACK_AFTER = `// 3.0 — \`T\` is constrained to Coordinatable, the closure trails
// without a label, and \`route\` no longer takes \`as:\`. Same pattern,
// tighter signature.
appCoordinator.setRoot(.authenticated) { (tab: MainTabCoordinator) in
    tab.selectFirstTab(.profile) { (profile: ProfileCoordinator) in
        profile.route(to: .userDetail(id: 123))
    }
}`;

export const CODE_MACRO_INJECT = `// 3.0 — opt this coordinator out of automatic environment injection.
@Scaffoldable(injectsCoordinator: false) @Observable
final class ReusableCoordinator: @MainActor FlowCoordinatable {
    var stack = FlowStack<ReusableCoordinator>(root: .home)
    func home() -> some View { ReusableHomeView() }
}`;

// Migration checklist (used by /docs/changelog).
export const MIGRATION = [
  {
    tag: 'Required',
    body: `Replace every <code>coordinator.view()</code> call with the property access <code>coordinator.view</code> (drop the parens).`
  },
  {
    tag: 'Required',
    body: `Replace <code>route(to: x, as: .sheet)</code> / <code>.fullScreenCover</code> with <code>present(x, as: .sheet)</code> / <code>.fullScreenCover</code>. Keep <code>route(to: x)</code> for pushes; the <code>as:</code> argument no longer exists on <code>route</code>.`
  },
  {
    tag: 'Required',
    body: `Re-spell the deep-link <code>&lt;T&gt;</code> overloads. Drop the <code>value:</code> label (the closure is now an unlabelled trailing closure), make sure the typed parameter is a <code>Coordinatable</code> (view-typed <code>T</code>s don't compile any more), and remove the <code>as:</code> argument from <code>route</code>. The overload still exists everywhere it did before, including a typed variant on <code>present(_:as:)</code> that hands you the resolved child once the modal lands.`
  },
  {
    tag: 'Compiler',
    body: `<code>onDismiss</code> and the deep-link trailing closures are now <code>@MainActor</code>-typed. If you stored or forwarded one as a plain <code>() -&gt; Void</code> / <code>(T) -&gt; Void</code>, update the type or annotate the closure.`
  },
  {
    tag: 'Platform',
    body: `Bump the consuming app's deployment target to iOS 18 / macOS 15 (and tvOS 18 / watchOS 11 / macCatalyst 18 if you ship those). The package no longer links against the old floors.`
  },
  {
    tag: 'Optional',
    body: `If you have coordinators whose views shouldn't see them in the environment, opt out with <code>@Scaffoldable(injectsCoordinator: false)</code>.`
  },
  {
    tag: 'Optional',
    body: `Modal hosting can be moved up the tree where it makes sense — <code>present(_:as:)</code> now works on <code>TabCoordinatable</code> and <code>RootCoordinatable</code> directly, so you no longer have to delegate every modal to a child flow.`
  }
];
