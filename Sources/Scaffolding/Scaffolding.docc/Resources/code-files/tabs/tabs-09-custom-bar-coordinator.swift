import SwiftUI
import Scaffolding

@Scaffoldable @Observable
final class AppCoordinator: @MainActor TabCoordinatable {
    var tabItems = TabItems<AppCoordinator>(
        tabs: [.planets, .favorites],
        visibility: .hidden          // native bar off
    )

    // No native bar ⇒ no label views needed. Plain `any Coordinatable`
    // returns are auto-tracked too, so both cases still exist.
    func planets() -> any Coordinatable { PlanetsCoordinator() }
    func favorites() -> any Coordinatable { FavoritesCoordinator() }

    // customize(_:) wraps the whole TabView — the right place to install
    // your own bar. It returns some View, so it must be ignored explicitly.
    @ScaffoldingIgnored
    func customize(_ view: AnyView) -> some View {
        view.safeAreaInset(edge: .bottom) { PlanetsTabBar() }
    }
}
