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
| `modalConfiguration` | `SheetConfiguration?` | Presenter-side sheet config (`detents`, `dragIndicator`, `interactiveDismissDisabled`) when presented with a configured `.sheet(...)`. |
| `badge` | `String?` | The tab badge, for tab destinations. |
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
            switch destination.routeType {
            case .push:
                Button { dismiss() } label: { Image(systemName: "chevron.left") }
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

Other uses: skip an in-view drag indicator when `modalConfiguration?.dragIndicator == .visible`; render compact layouts when `presentationType == .sheet` with a `.medium` detent available.

## Caveats

- The default value (outside any coordinator hierarchy — most importantly `#Preview`) is a dummy that reads as `.root`. Don't build preview assertions on it; see `previews.md`.
- `Destination` is metadata, not a navigation handle — to navigate, use the typed coordinator.
- Don't write `\.destination` yourself; the framework injects it at materialisation.
