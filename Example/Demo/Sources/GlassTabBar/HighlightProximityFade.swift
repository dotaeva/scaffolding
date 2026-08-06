import SwiftUI

/// Active-layer opacity `1 - min(|slideIndex - index|, 1)`: fully lit under
/// the pill, crossfading over one tab's distance. Animatable so the tint
/// tracks the pill per frame while a tap spring travels across tabs.
struct HighlightProximityFade: ViewModifier, Animatable {
    var slideIndex: CGFloat
    let index: Int

    nonisolated var animatableData: CGFloat {
        get { slideIndex }
        set { slideIndex = newValue }
    }

    func body(content: Content) -> some View {
        content.opacity(1 - min(abs(slideIndex - CGFloat(index)), 1))
    }
}
