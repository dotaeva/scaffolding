import SwiftUI
import Scaffolding

/// A flow hosted as one of `MainTabCoordinator`'s tabs.
///
/// The bottom room the glass bar needs is declared once here rather than on
/// every screen. A flow's `customize(_:)` wraps that flow's whole
/// `NavigationStack` and `contentMargins` propagates down from there, so
/// pushed screens (developer, transaction detail, …) inherit it along with
/// the tab's root.
///
/// This is the right level for the inset. `MainTabCoordinator.customize` is
/// too high — that wraps the `TabView`, which re-establishes the safe area
/// for its children — and per-screen is too low.
///
/// The bar's *scroll* behaviour cannot be hoisted the same way; it is
/// installed once on the tab chrome instead — see `tracksScrollForTabBar`.
@MainActor
protocol GlassTabFlow: FlowCoordinatable {}

extension GlassTabFlow {
    func customize(_ view: AnyView) -> some View {
        view.glassTabBarInset()
    }
}
