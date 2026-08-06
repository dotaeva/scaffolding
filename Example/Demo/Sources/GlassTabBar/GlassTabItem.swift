import SwiftUI

struct GlassTabItem: Identifiable, Equatable {
    /// The tab's `Destination.id`. Labels can't serve as identity — the same
    /// destination case may appear as several tabs (e.g. duplicate promos).
    let id: UUID
    let label: String
    /// SF Symbol name.
    let systemImage: String
    /// Optional badge text, mirrored from the tab's `Destination.badge`.
    var badge: String? = nil
}
