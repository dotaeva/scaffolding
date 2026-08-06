import SwiftUI

@MainActor
@Observable
final class GlassTabBarModel {
    /// The *applied* selection — written by the coordinator sync, never by
    /// the bar itself. Bar taps go through `onSelect`, whose owner decides
    /// whether they are applied (see MainTabCoordinator.barTapped).
    var selectedIndex = 0
    /// true = minimized (icons only), false = expanded (icons + labels).
    var isMinimized = false
    /// Fractional position of the highlight pill in tab-index space.
    /// Animated on taps, driven 1:1 by the finger while scrubbing.
    var slideIndex: CGFloat = 0
    /// While scrubbing, the finger owns the highlight — nothing else may
    /// retarget it with a spring.
    var isDragging = false
    /// Navigation callback for taps/scrub releases. Also fires for re-taps
    /// of the current tab — `selectedIndex` alone can't surface those.
    var onSelect: ((Int) -> Void)?

    /// Choosing a tab is a deliberate bar interaction — surface the labels.
    func select(_ index: Int) {
        setMinimized(false)
        onSelect?(index)
    }

    /// Retarget the highlight without touching the applied selection —
    /// used to snap back when a tap was vetoed by shouldSelect.
    func slide(to index: Int) {
        guard !isDragging else { return }
        withAnimation(.tabSlide) {
            slideIndex = CGFloat(index)
        }
    }

    /// The guard keeps per-frame scroll events from restarting (and visibly
    /// stuttering) an in-flight minimize spring.
    func setMinimized(_ minimized: Bool) {
        guard isMinimized != minimized else { return }
        withAnimation(.tabBarMinimize) {
            isMinimized = minimized
        }
    }
}
