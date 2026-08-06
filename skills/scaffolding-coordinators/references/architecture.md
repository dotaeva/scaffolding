# Architecture and discipline

## The hard rule: never nest `NavigationStack`

`FlowCoordinatable` already wraps a `NavigationStack`. SwiftUI does not compose nested stacks — the inner one swallows pushes and `route(to:)` stops working. **Never** put `NavigationStack`, `NavigationView`, `NavigationSplitView`, or any container holding a `NavigationPath` inside any view returned by a route function — not the root view, not a pushed detail, not a `customize` wrapper.

```swift
// ❌ Breaks routing.
func detail(item: Item) -> some View {
    NavigationStack { DetailRoot(item: item) }
}

// ✅ A screen that needs its own hierarchy is a child coordinator.
func detail(item: Item) -> any Coordinatable {
    DetailCoordinator(item: item)
}
```

## Picking a navigation primitive

```
Is it a push/pop on the current stack?
├─ Yes → coordinator.route(to: .someDestination)
└─ No, it's a modal.
   Is the modal a single screen (confirmation, info, simple form, picker)?
   ├─ Yes → SwiftUI native: .sheet(item:) / .fullScreenCover(item:) / .alert
   └─ No, it contains its own flow (steps, pushes, dismiss-with-result)
      → coordinator.present(.subflow, as: .sheet)  // route returns a child coordinator
```

| You want… | Use |
|---|---|
| Push a screen | `route(to: .screen(args:))` |
| Pop one screen | `pop()` (or `@Environment(\.dismiss)` in the view) |
| Pop to root | `popToRoot()` |
| Confirmation dialog | native `.alert` / `.confirmationDialog` |
| One-screen sheet | native `.sheet(item:)` with local `@State` |
| Multi-step sub-flow modal | `present(.subflow, as: .sheet)` |
| Full-screen sub-flow | `present(.subflow, as: .fullScreenCover)` |
| Close a modal you presented | `dismissModal()` |
| Close the whole sub-flow from inside | `dismissCoordinator()` |
| Replace the entire hierarchy | `RootCoordinatable.setRoot(_:)` |
| Switch tabs programmatically | `selectFirstTab(_:)` / `select(index:)` |
| Guard/redirect a tab tap | override `shouldSelect(tab:isReselection:)` |

Stay native for view-only modals — lighter, no extra `Destinations` case.

## Separation of concerns

**Views never own navigation state.**
- ❌ `@State path: [SomeType]`, `@State isPresented` for flow-level sheets, `@Binding path` to pop, `NavigationLink(value:)` for flow pushes.
- ✅ Read the coordinator from `@Environment(HomeCoordinator.self)` and call `route(to:)` / `present(_:as:)` / `pop()`. A plain `Button { coordinator.route(to: .detail(item: planet)) }` replaces `NavigationLink`.
- Local `@State` + `.sheet(item:)` is fine for genuine single-screen, view-only modals.

**Coordinators don't render.** Their job is route declaration + state mutation. No `@Environment` reads (they aren't views), no view construction beyond returning route content.

**Modules expose coordinators, not views.** The unit of import is the coordinator type; callers hold a reference and route to its surface without knowing its internals.

**Results flow through constructor callbacks or the `awaiting:` API**, never by the presenter observing the child's state. See `scaffolding-routing` → `dismissal-and-results.md`.

## Orienting in a nested hierarchy

Deep trees (root → tabs → flows → presented sub-flows) make it easy to lose track of which coordinator owns a screen. Don't guess:

- **View → nearest coordinator:** `@Environment(HomeCoordinator.self)`. All ancestors are injected too (`@Environment(AppCoordinator.self)` from any depth) — see `scaffolding-environment`.
- **Coordinator → ancestor:** `ancestor(ofType: AppCoordinator.self)` walks the `parent` chain to the nearest match (`nil` when absent). The right way to expose e.g. a sign-out that belongs to the app root: `ancestor(ofType: AppCoordinator.self)?.setRoot(.unauthenticated)`.
- **Coordinator → descendant:** typed deep-link closures / `expecting:` overloads (`scaffolding-routing` → `deep-linking.md`). Never store child references.
- **Where am I:** `coordinator.routeType` says how the coordinator was presented (`.root` / `.push` / `.sheet` / `.fullScreenCover`; `routeType.isModal` collapses the modal cases). Views ask the same about their own screen via `@Environment(\.destination).routeType` — the two can differ (a view pushed inside a sheet-presented flow reads `.push`; its flow reads `.sheet`). Flow stack queries (`depth`, `topDestination`, `isInStack`, `count(of:)`, `isPresentingModal`) are in `scaffolding-routing` → `push-pop.md`.
- **Debugging:** `print(coordinator.hierarchyRoot.debugHierarchy())` dumps the whole live tree from anywhere, side-effect-free — verify your mental model against it before changing navigation code (see `scaffolding-state-restoration`).

## Common mistakes checklist (what NOT to generate)

1. `NavigationStack` anywhere inside a flow's view tree.
2. Blanket `@ScaffoldingIgnored` on properties / `Void` helpers — never tracked, annotation is noise.
3. Navigation state (`path`, sheet booleans) held in views.
4. `route(to: .x, as: .sheet)` — that API was **split**; push is `route(to:)`, modal is `present(_:as:)`. There is no `as:` on `route`.
5. `NavigationLink` to push within a flow.
6. `dismissCoordinator()` to close one screen — it removes the **whole coordinator** from its parent. One screen is `pop()`.
7. Concrete coordinator return types (`-> LoginCoordinator`) expecting a destination case — must be `any Coordinatable`.
8. Inventing a new coordinator type to host a single route — the closest existing coordinator should own it.

## Compatibility

- Swift 6.2 toolchain (`@Observable`, macros, strict concurrency). Platform floor iOS 18 / macOS 15 / tvOS 18 / watchOS 11 / macCatalyst 18; `TabRole` is available unconditionally.
- `onDismiss` and deep-link closures are `@MainActor`-typed — annotate closures you forward.
- Native environment values (`\.dismiss`, `\.scenePhase`, `\.openURL`) compose fine; `\.dismiss` works for both pops and modal dismissal because Scaffolding wraps `NavigationStack`.
- `fullScreenCover` does not exist on macOS — container covers are rendered only on iOS-family platforms; prefer `.sheet` for cross-platform modals.
- Only **one modal at a time** per layer is supported; presenting a second queues it until the first is dismissed (a runtime warning is logged).
