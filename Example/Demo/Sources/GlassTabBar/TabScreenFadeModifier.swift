import SwiftUI

extension View {
    /// A subtle fade + micro-scale as a tab's screen becomes focused,
    /// mirroring expo-glass-tabs' `renderFadingTabScreen`. Apply to each
    /// tab's *root* view — pushed screens already get the stack transition.
    func tabScreenFade() -> some View {
        modifier(TabScreenFadeModifier())
    }
}

struct TabScreenFadeModifier: ViewModifier {
    /// Starts at 1 so the very first screen on app launch doesn't animate;
    /// `onDisappear` re-arms the entrance for the next tab switch.
    @State private var progress: CGFloat = 1

    func body(content: Content) -> some View {
        content
            .opacity(progress)
            // Whisper of depth; never enter from nothing (scale ≥ 0.985).
            .scaleEffect(0.985 + 0.015 * progress)
            .onAppear {
                guard progress < 1 else { return }
                // Strong ease-out — entering content should feel instant,
                // then settle.
                withAnimation(.timingCurve(0.23, 1, 0.32, 1, duration: 0.22)) {
                    progress = 1
                }
            }
            .onDisappear {
                progress = 0
            }
    }
}
