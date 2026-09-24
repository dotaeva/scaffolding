# `\.destination` — presentation metadata

Every view materialised through a coordinator receives a `Destination` value describing *how it got on screen*:

```swift
@Environment(\.destination) private var destination
```

## Public surface

| Property | Type | Meaning |
|---|---|---|
| `routeType` | `DestinationType` | How this destination was routed **within its coordinator**: `.root`, `.push`, `.sheet`, `.fullScreenCover`. A coordinator's root is `.root` even when the whole coordinator was presented modally. |
| `presentationType` | `DestinationType` | The **effective** on-screen presentation. For a flow presented as a sheet, the flow's root view reads `presentationType == .sheet` while `routeType == .root`. |
| `meta` | `any DestinationMeta` | Which `Destinations` case produced this screen (case name, no associated values). |
| `accessibilityIdentifier` | `String?` | Identifier for a native tab item, when set. |
| `badge` | `String?` | The tab badge, for tab destinations. |
| `column` | `SplitColumn?` | Structural split column, when applicable. |
| `id` | `UUID` | Stable identity of this destination instance. |

**`routeType` vs `presentationType`** — use `routeType` for "what is my role in my own flow" (root screens hide the back button); use `presentationType` for "how am I actually displayed" (show a Close button on anything that arrived modally, including the root of a presented sub-flow).

## Matching `meta`

`meta` is existential; cast it to a concrete coordinator's `Meta` to compare:

```swift
if let meta = destination.meta as? HomeCoordinator.Destinations.Meta, meta == .detail {
    // this screen is the .detail route
}
```

Switch on it when one view renders different layouts depending on which route reached it.

## Canonical pattern — adaptive chrome

One reusable bar that adapts to push / sheet / cover / root without knowing the surrounding flow:

```swift
import SwiftUI
import Scaffolding

struct AdaptiveTopBar: View {
    let title: String

    @Environment(\.destination) private var destination
    // Scaffolding wraps NavigationStack, so native dismiss handles
    // both pops and modal dismissals.
    @Environment(\.dismiss)     private var dismiss

    var body: some View {
        HStack {
            switch destination.presentationType {
            case .push:
                Button("Back", systemImage: "chevron.left") { dismiss() }
            case .sheet, .fullScreenCover:
                Button("Close") { dismiss() }
            case .root:
                Color.clear.frame(width: 24)
            }
            Spacer()
            Text(title).font(.headline)
            Spacer()
            Color.clear.frame(width: 24, height: 1)
        }
        .padding(.horizontal, 16)
        .frame(height: 44)
    }
}
```

Configure presentation with SwiftUI modifiers on the presented view or child
coordinator's `customize(_:)`. Keep settings your UI needs in view inputs or
state. `modalConfiguration` and `SheetConfiguration` are deprecated legacy
metadata; native modifiers do not populate them.

## Caveats

- The default value (outside any coordinator hierarchy — most importantly `#Preview`) is a dummy that reads as `.root`. Don't build preview assertions on it; see `previews.md`.
- `Destination` supplies metadata and a dismissal handle. Use `dismiss()` / `dismiss(returning:)` to remove this exact destination; use the typed coordinator to start navigation.
- Don't write `\.destination` yourself; the framework injects it at materialisation.
