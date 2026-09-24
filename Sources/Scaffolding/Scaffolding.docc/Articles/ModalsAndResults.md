# Presenting Modals and Results

Present sheets and covers, close them from either side, and get a value back.

## Overview

Every coordinator can present. Each presentation host shows one request at a
time; a presented child flow is a new host and can present its own modals.
Keep view-only confirmations native with `.alert` or `.sheet(item:)`.

## Present

<!-- checked-swift: modal-presentation -->
```swift
present(.settings)                                  // sheet by default
present(.player, as: .fullScreenCover)
present(.filters, as: .sheet)
present(.settings, policy: .distinct)               // skip if this case is already requested
```

`as:` takes ``ModalPresentationType/sheet`` (the default) or
``ModalPresentationType/fullScreenCover``. On macOS a cover renders as a
sheet but still reports `.fullScreenCover`. `.distinct` skips a case that is
already requested, including queued requests.

## Configure presented content

Sizing and dismissal behavior are SwiftUI modifiers on the presented content.
For a view route, apply them in the route's class-body factory:

<!-- checked-swift: sheet-view-modifiers -->
```swift
func filters() -> some View {
    FiltersView()
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(true)
}
```

For a child coordinator, apply them in `customize(_:)`, declared in an
extension, so they cover every screen of its flow:

<!-- checked-swift: sheet-flow-modifiers -->
```swift
extension SettingsCoordinator {
    func customize(_ view: AnyView) -> some View {
        view
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
    }
}
```

The presenter still calls `present(.settings, as: .sheet)`. Keep the route's
return type `any Coordinatable`: returning `SettingsCoordinator().view` would
make it a view route and drop the child relationship.

When settings vary, pass them as ordinary inputs. If you disable interactive
dismissal, provide a button that calls `destination.dismiss()` or
`dismissCoordinator()`.

## Close

Pick the call by the request you want gone. Here A, B, and C belong to the
same coordinator; A is visible:

![A is visible; B and C are queued. dismissPresentedModal closes A and advances B. dismissModal removes only C. cancelPendingModals removes both B and C while preserving A.](modal-queue)

| From | Call | Removes |
|---|---|---|
| Presenter | ``Coordinatable/dismissPresentedModal()`` | The visible request; the next one shows |
| Presenter | ``Coordinatable/dismissModal()`` | Its latest request, even a queued one |
| Presenter | ``Coordinatable/cancelPendingModals()`` | Its queued requests; the visible one stays |
| Presenter | ``Coordinatable/dismissAllModals()`` | All its requests and their descendants |
| Child coordinator | ``Coordinatable/dismissCoordinator()`` | The whole child flow |
| Any presented view | `destination.dismiss()` or native `dismiss()` | That presentation |

- `dismissPresentedModal()` targets the shared host, so it can close a nested
  flow's request. The other presenter calls touch only the receiver's own
  requests.
- `pop()` also removes a modal when it is the flow's last entry.
- `isPresentingModal` counts queued requests; `pendingModalCount` counts own
  requests behind the visible one.
- Shared flow stacks queue in hierarchy order, not presentation time.

## Await a result

![The presenter awaits a picker while the child remains interactive. The child dismisses its flow returning an item; the presenter resumes after the branch is removed. Ordinary dismissal returns nil. Cancelling the waiting task leaves the UI in place.](result-lifecycle)

`present(_:as:policy:awaiting:)` and ``FlowCoordinatable/route(to:policy:awaiting:)``
suspend until the destination leaves:

<!-- checked-swift: navigation-value -->
```swift
if let item = await present(.picker, awaiting: Item.self) {
    apply(item)
}
```

Return the value from the other side:

| From | Call |
|---|---|
| The child coordinator | ``Coordinatable/dismissCoordinator(returning:)`` |
| A view in the destination | ``Destination/dismiss(returning:)`` via `@Environment(\.destination)` |

```swift
struct TagPicker: View {
    @Environment(\.destination) private var destination

    var body: some View {
        Button("Urgent") { destination.dismiss(returning: Tag.urgent) }
    }
}
```

- A swipe, back gesture, `pop()`, or dismissal without a value returns `nil`.
  So does a mismatched type. `awaiting: Void.self` waits only.
- The waiter resumes once, after the branch is detached, so it can navigate
  again immediately.
- Cancelling the waiting task returns `nil` and leaves the UI in place. A task
  cancelled before the call creates no destination.
- A `.distinct` skip returns `nil` at once.

Start the wait from a view with an ordinary task:

```swift
Button("Change limit") { Task { await coordinator.changeLimit() } }
```

## See a result in Atlas

@Row(numberOfColumns: 3) {
    @Column(size: 1) {
        @Video(source: atlas-planner-result.mp4, poster: atlas-planner-result-poster.png, alt: "The Dolomites opens Planner as a sheet. Planner pushes Review, saves the journey, and dismisses. Places shows the saved-result message, whose action opens that journey in Saved.")
    }
    @Column(size: 2) {
        Recorded in the [Atlas example](https://github.com/dotaeva/scaffolding/tree/main/Example/Atlas) on an **iPhone 17 simulator with iOS 26.4**.

        1. **Plan a journey.** Places presents Planner as a sheet and awaits a `TripPlan`.
        2. **Review.** Planner pushes a screen inside its own modal stack.
        3. **Save journey.** Planner closes its whole flow and returns the plan.
        4. **Open the journey.** Places receives the plan and opens it in Saved.

        ```swift
        // Places
        let plan = await present(.planner, awaiting: TripPlan.self)

        // Planner
        dismissCoordinator(returning: completedPlan)
        ```
    }
}

## Configure the child, then await

Add `expecting:` to get the child immediately. Add both labels to configure it
before waiting. This runs inside an async coordinator action:

<!-- checked-swift: combined-navigation -->
```swift
let (settings, result) = present(
    .settings, as: .sheet,
    expecting: SettingsCoordinator.self, awaiting: Void.self
)
settings?.route(to: .account)
_ = await result() // wait until the whole settings flow closes

let picking = route(
    to: .picker, expecting: PickerCoordinator.self, awaiting: Item.self
)
picking.coordinator?.route(to: .favorites)
if let item = await picking.result() {
    apply(item)
}
```

The call returns `(coordinator: T?, result: @MainActor () async -> Result?)`
without suspending.

- A view route or a wrong type gives a `nil` coordinator; `result()` still works.
- A `.distinct` skip gives a `nil` coordinator and a `result()` that returns
  `nil` immediately.
- `result()` observes the original destination, even if it already closed.
  Calling it again returns the same value.
- Cancelling the task running `result()` releases only that wait.

## Report repeatedly with a callback

`awaiting:` delivers one value. When a child reports several times, or before
it closes, pass a closure as a route parameter:

```swift
func login(onComplete: @escaping @MainActor (AuthToken) -> Void) -> any Coordinatable {
    LoginCoordinator(onComplete: onComplete)
}

func startLogin() {
    present(.login(onComplete: { [weak self] in self?.session = $0 }))
}
```

A closure parameter makes the route non-`Codable`, so it cannot be restored.

## API

| Intent | Method |
|---|---|
| Present | ``Coordinatable/present(_:as:policy:)`` |
| Present and use the child | ``Coordinatable/present(_:as:policy:expecting:)`` |
| Present and await a result | ``Coordinatable/present(_:as:policy:awaiting:)`` |
| Both | ``Coordinatable/present(_:as:policy:expecting:awaiting:)`` |
| Close | `dismissPresentedModal()`, `dismissModal()`, `cancelPendingModals()`, `dismissAllModals()`, `dismissCoordinator()` |
| Return a value | `dismissCoordinator(returning:)`, `destination.dismiss(returning:)` |
| Inspect | `isPresentingModal`, `pendingModalCount` |

## See Also

- <doc:Essentials>
- <doc:Flows>
- <doc:DeepLinking>
