import SwiftUI

/// Transform-only slide so the pill's travel never triggers layout, and
/// `animatableData` keeps the position continuous per frame — both while
/// a tap spring is in flight and while the minimize spring reshapes the bar.
struct HighlightSlideEffect: GeometryEffect {
    var slideIndex: CGFloat
    var itemWidth: CGFloat

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(slideIndex, itemWidth) }
        set {
            slideIndex = newValue.first
            itemWidth = newValue.second
        }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(
            CGAffineTransform(
                translationX: TabBarMetrics.rowPadding + itemWidth * slideIndex,
                y: 0
            )
        )
    }
}
