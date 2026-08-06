import SwiftUI

extension View {
    /// Hides scrolling content behind the status bar.
    ///
    /// Screens that hide the navigation bar get no scroll-edge effect from
    /// the system — `scrollEdgeEffectStyle` only renders where content meets
    /// a bar — so without this, scrolled content collides with the clock.
    func statusBarScrim() -> some View {
        overlay(alignment: .top) { StatusBarScrim() }
    }
}

struct StatusBarScrim: View {
    var body: some View {
        LinearGradient(
            stops: [
                .init(color: ScreenBackground.color, location: 0),
                .init(color: ScreenBackground.color, location: 0.72),
                .init(color: .clear, location: 1),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: 76)
        // Anchored to the very top of the screen, not the safe area.
        .ignoresSafeArea(edges: .top)
        .allowsHitTesting(false)
    }
}
