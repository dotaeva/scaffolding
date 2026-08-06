import SwiftUI

extension View {
    /// Reserves bottom room for the floating glass tab bar.
    ///
    /// `TabView` already contributes a native tab-bar inset to each tab's
    /// content, and it survives `setTabBarVisibility(.hidden)` — hiding the
    /// bar is visual only, the reservation stays. Measured on a device with a
    /// home indicator that inset is 83pt (34 indicator + 49 bar), which does
    /// happen to clear the glass bar's 76pt footprint.
    ///
    /// It is not something to rely on, though: without a home indicator it
    /// drops to ~49pt while the bar sits *higher* (70pt), so the content
    /// would collide. Screens reserve the bar's own footprint instead.
    ///
    /// Note this has to be applied inside the tab's content. The same
    /// modifier in `MainTabCoordinator.customize` is a no-op — that wraps the
    /// `TabView`, which re-establishes the safe area for its children.
    func glassTabBarInset() -> some View {
        contentMargins(.bottom, 24, for: .scrollContent)
    }
}
