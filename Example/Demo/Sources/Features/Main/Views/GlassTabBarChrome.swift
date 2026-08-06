import SwiftUI

/// Installed by `MainTabCoordinator.customize`: the glass bar overlaid on the
/// `TabView`, plus the two-way sync between the bar and the coordinator's
/// selection.
struct GlassTabBarChrome: ViewModifier {
    let coordinator: MainTabCoordinator
    let model: GlassTabBarModel

    func body(content: Content) -> some View {
        content
            // The bar positions itself internally; transparent regions pass
            // touches through.
            .overlay {
                if coordinator.showsGlassBar {
                    GlassTabBar(items: coordinator.barItems, model: model)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.tabBarMinimize, value: coordinator.showsGlassBar)
            // One install point for the whole tab tree — see the modifier's
            // note on why a per-screen SwiftUI modifier can't cover pushed
            // screens.
            .tracksScrollForTabBar(model)
            .environment(model)
            .onAppear {
                model.selectedIndex = coordinator.selectedIndex
                model.slideIndex = CGFloat(coordinator.selectedIndex)
                model.onSelect = { [coordinator] index in
                    coordinator.barTapped(index)
                }
            }
            // Applied selection (accepted taps, deep links, the developer
            // screen's select calls) reflects back into the bar.
            .onChange(of: coordinator.selectedIndex) { _, index in
                model.selectedIndex = index
            }
    }
}
