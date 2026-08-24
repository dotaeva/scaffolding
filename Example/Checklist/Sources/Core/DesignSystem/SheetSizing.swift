import SwiftUI

extension View {
    /// Gives a sheet a usable size on macOS.
    ///
    /// iOS sizes sheets with `presentationDetents`, which the presenter
    /// sets per call site. macOS has no detents: it sizes a sheet to its
    /// content's *ideal* size, and `List`, `Form`, and `Color` have none —
    /// so a sheet full of rows collapses to a sliver. Every screen that can
    /// be presented modally claims a minimum and an ideal here; on iOS the
    /// modifier is a no-op, leaving the detents in charge.
    ///
    /// For a modal *flow*, apply it in the coordinator's `customize(_:)` so
    /// the whole `NavigationStack` is sized once and every pushed screen
    /// inherits it.
    func sheetSizing(
        minWidth: CGFloat = 480,
        idealWidth: CGFloat = 620,
        minHeight: CGFloat = 420,
        idealHeight: CGFloat = 560
    ) -> some View {
        #if os(macOS)
        frame(
            minWidth: minWidth,
            idealWidth: idealWidth,
            minHeight: minHeight,
            idealHeight: idealHeight
        )
        #else
        self
        #endif
    }
}
